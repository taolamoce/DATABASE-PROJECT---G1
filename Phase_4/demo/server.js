require("dotenv").config();
const express = require("express");
const mysql = require("mysql2/promise");
const path = require("path");
const app = express();
const pool = mysql.createPool({
  host: process.env.MYSQL_HOST || "127.0.0.1",
  port: Number(process.env.MYSQL_PORT || 3306),
  user: process.env.MYSQL_USER || "root",
  password: process.env.MYSQL_PASSWORD || "",
  database: process.env.MYSQL_DATABASE || "lab_asset_tracker",
  waitForConnections: true,
  connectionLimit: 5,
  dateStrings: true,
});
app.use(express.json({ limit: "32kb" }));
app.use(express.static(path.join(__dirname, "public")));
const run = async (sql, params = []) => {
  const [rows] = await pool.execute(sql, params);
  return rows;
};
const error = (res, e) => {
  console.error("Database error:", e.code || e.sqlState || "unknown");
  const status =
    [
      "ER_DUP_ENTRY",
      "ER_NO_REFERENCED_ROW_2",
      "ER_ROW_IS_REFERENCED_2",
      "ER_CHECK_CONSTRAINT_VIOLATED",
    ].includes(e.code) || e.sqlState === "45000"
      ? 400
      : 500;
  res.status(status).json({
    error:
      status === 400
        ? e.sqlMessage
        : "Database connection or query failed. Check the server configuration.",
    code: e.code || "DB_ERROR",
    sqlState: e.sqlState || null,
  });
};
const route = (url, handler) =>
  app.get("/api/" + url, async (req, res) => {
    try {
      res.json(await handler(req));
    } catch (e) {
      error(res, e);
    }
  });
route("health", async () => {
  await run("SELECT 1");
  return {
    ok: true,
    database: process.env.MYSQL_DATABASE || "lab_asset_tracker",
  };
});
route("overview", async () => {
  const [rows] = await pool.query(
    "SELECT (SELECT COUNT(*) FROM lab) AS labs,(SELECT COUNT(*) FROM equipment) AS equipment,(SELECT COUNT(*) FROM chemical) AS chemicals,(SELECT COUNT(*) FROM research_grant) AS grants,(SELECT COUNT(*) FROM personnel) AS personnel,(SELECT COUNT(*) FROM access_log) AS logs",
  );
  return rows[0];
});
route("labs", () =>
  run(
    "SELECT lab_id AS id,lab_name AS name,building,room_number AS room,hazard_level AS hazard FROM lab ORDER BY lab_id",
  ),
);
route("equipment", () =>
  run(
    "SELECT equipment_id AS id,name,model,serial_number AS serial,purchase_date AS purchased,status,lab_id AS lab FROM equipment ORDER BY equipment_id",
  ),
);
route("chemicals", () =>
  run(
    "SELECT chemical_id AS id,name,cas_number AS cas,hazard_class AS hazard,quantity AS qty,unit,storage_location AS storage,lab_id AS lab FROM chemical ORDER BY chemical_id",
  ),
);
route("personnel", () =>
  run(
    `SELECT p.person_id AS id,p.full_name AS name,p.person_type AS type,COALESCE((SELECT MAX(CASE c.hazard_level WHEN 'High' THEN 3 WHEN 'Medium' THEN 2 WHEN 'Low' THEN 1 ELSE 0 END) FROM person_certification pc JOIN certification c ON c.cert_id=pc.cert_id WHERE pc.person_id=p.person_id AND pc.status='Active' AND CURDATE() BETWEEN pc.issue_date AND pc.expiry_date),0) AS \`rank\` FROM personnel p ORDER BY p.person_id`,
  ),
);
route("grants", () =>
  run(
    "SELECT grant_id AS id,title,funding_agency AS agency,amount,pi_id AS pi,start_date AS start,end_date AS end FROM research_grant ORDER BY grant_id",
  ),
);
route("audit", () =>
  run(
    "SELECT a.log_id AS id,a.access_timestamp AS time,p.full_name AS person,a.person_id AS personId,a.lab_id AS lab,a.access_type AS type,a.authorized_flag AS authorized FROM access_log a JOIN personnel p ON p.person_id=a.person_id ORDER BY a.log_id DESC LIMIT 100",
  ),
);
app.post("/api/equipment", async (req, res) => {
  const x = req.body;
  try {
    if (!/^EQP-\d{3}$/.test(x.id || "") || !x.name || !x.lab)
      return res
        .status(400)
        .json({ error: "Valid equipment ID, name and lab are required" });
    await run(
      "INSERT INTO equipment(equipment_id,name,model,serial_number,purchase_date,status,lab_id) VALUES(?,?,?,?,?,?,?)",
      [
        x.id,
        x.name,
        x.model || null,
        x.serial || null,
        x.purchased || null,
        x.status || "Active",
        x.lab,
      ],
    );
    res.status(201).json({ ok: true });
  } catch (e) {
    error(res, e);
  }
});
app.put("/api/equipment/:id", async (req, res) => {
  const x = req.body;
  try {
    const result = await run(
      "UPDATE equipment SET name=?,model=?,serial_number=?,purchase_date=?,status=?,lab_id=? WHERE equipment_id=?",
      [
        x.name,
        x.model || null,
        x.serial || null,
        x.purchased || null,
        x.status,
        x.lab,
        req.params.id,
      ],
    );
    if (!result.affectedRows)
      return res.status(404).json({ error: "Equipment not found" });
    res.json({ ok: true });
  } catch (e) {
    error(res, e);
  }
});
app.delete("/api/equipment/:id", async (req, res) => {
  try {
    const result = await run("DELETE FROM equipment WHERE equipment_id=?", [
      req.params.id,
    ]);
    if (!result.affectedRows)
      return res.status(404).json({ error: "Equipment not found" });
    res.json({ ok: true });
  } catch (e) {
    error(res, e);
  }
});
app.post("/api/access", async (req, res) => {
  const { personId, labId, type, at, requireAuthorization } = req.body;
  try {
    if (
      !/^PER-\d{5}$/.test(personId || "") ||
      !/^LAB-\d{3}$/.test(labId || "") ||
      !["Entry", "Exit"].includes(type) ||
      !/^\d{4}-\d\d-\d\d$/.test(at || "")
    )
      return res.status(400).json({ error: "Invalid access request" });
    // Request TRUE so BR15 trigger actually raises SQLSTATE 45000 for insufficient clearance.
    const result = await run(
      "INSERT INTO access_log(person_id,lab_id,access_timestamp,access_type,authorized_flag) VALUES(?,?,?, ?, ?)",
      [
        personId,
        labId,
        at + " 12:00:00",
        type,
        requireAuthorization === false ? 0 : 1,
      ],
    );
    const rows = await run(
      "SELECT log_id AS id,authorized_flag AS authorized FROM access_log WHERE log_id=?",
      [result.insertId],
    );
    res.status(201).json({
      ok: true,
      ...rows[0],
      message: rows[0].authorized
        ? "Trigger granted access"
        : "Trigger recorded unauthorized attempt with FALSE flag",
    });
  } catch (e) {
    error(res, e);
  }
});
app.get("/api/*", (req, res) =>
  res.status(404).json({ error: "Unknown API route" }),
);
const port = Number(process.env.PORT || 3000);
app.listen(port, "127.0.0.1", () =>
  console.log(`G1 Lab Tracker: http://localhost:${port}`),
);
