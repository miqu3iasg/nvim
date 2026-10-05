-- lua/snippets/sql.lua

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local rep = require("luasnip.extras").rep

local function bare(name)
  return name:match("([%w_]+)$") or ""
end

local function index_name(args)
  local cols = args[2][1]:gsub("[%s,]+", "_")
  return "idx_" .. bare(args[1][1]) .. "_" .. cols
end

local function join_snip(trig, kind)
  return s(trig, {
    t(kind .. " JOIN "), i(1, "table"), t(" "), i(2, "b"),
    t(" ON "), rep(2), t("."), i(3, "id"),
    t(" = "), i(4, "a"), t("."), i(5, "fk"),
    i(0),
  })
end

return {
  -- Selects
  s("sel", { t("SELECT * FROM "), i(1, "table"), t(";"), i(0) }),

  s("selw", {
    t("SELECT "), i(1, "*"),
    t({ "", "FROM " }), i(2, "table"),
    t({ "", "WHERE " }), i(3, "condition"), t(";"),
    i(0),
  }),

  s("selc", {
    t("SELECT COUNT(*) FROM "), i(1, "table"),
    t({ "", "WHERE " }), i(2, "condition"), t(";"),
    i(0),
  }),

  -- Count per group, biggest first
  s("selg", {
    t("SELECT "), i(1, "column"), t({ ", COUNT(*) AS total", "FROM " }), i(2, "table"),
    t({ "", "GROUP BY " }), rep(1),
    t({ "", "ORDER BY total DESC;" }),
    i(0),
  }),

  -- Select with one join, aliases mirrored
  s("selj", {
    t("SELECT "), rep(2), t(".*, "), rep(4), t(".*"),
    t({ "", "FROM " }), i(1, "table"), t(" "), i(2, "a"),
    t({ "", "INNER JOIN " }), i(3, "other"), t(" "), i(4, "b"),
    t(" ON "), rep(2), t("."), i(5, "id"), t(" = "), rep(4), t("."), i(6, "fk"),
    t({ "", "WHERE " }), i(7, "condition"), t(";"),
    i(0),
  }),

  -- JOIN clauses
  join_snip("ij", "INNER"),
  join_snip("lj", "LEFT"),

  -- Clauses
  s("ob", { t("ORDER BY "), i(1, "column"), t(" "), c(2, { t("ASC"), t("DESC") }), i(0) }),
  s("gb", { t("GROUP BY "), i(1, "column"), i(0) }),

  -- DML
  s("ins", {
    t("INSERT INTO "), i(1, "table"), t(" ("), i(2, "col1, col2"),
    t({ ")", "VALUES (" }), i(3, "val1, val2"), t(");"),
    i(0),
  }),

  s("insm", {
    t("INSERT INTO "), i(1, "table"), t(" ("), i(2, "col1, col2"),
    t({ ")", "VALUES", "    (" }), i(3, "v1, v2"),
    t({ "),", "    (" }), i(4, "v1, v2"), t(");"),
    i(0),
  }),

  s("upd", {
    t("UPDATE "), i(1, "table"),
    t({ "", "SET " }), i(2, "column"), t(" = "), i(3, "value"),
    t({ "", "WHERE " }), i(4, "condition"), t(";"),
    i(0),
  }),

  s("del", {
    t("DELETE FROM "), i(1, "table"),
    t({ "", "WHERE " }), i(2, "condition"), t(";"),
    i(0),
  }),

  -- DDL
  s("ct", {
    t("CREATE TABLE "), i(1, "table"),
    t({ " (", "    id BIGSERIAL PRIMARY KEY,", "    " }),
    i(2, "name"), t(" "), i(3, "VARCHAR(255)"),
    t({
      " NOT NULL,",
      "    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP",
      ");",
    }),
    i(0),
  }),

  s("at", {
    t("ALTER TABLE "), i(1, "table"),
    t({ "", "ADD COLUMN " }), i(2, "column"), t(" "), i(3, "type"), t(";"),
    i(0),
  }),

  s("ci", {
    t("CREATE INDEX "), f(index_name, { 1, 2 }),
    t(" ON "), i(1, "table"), t(" ("), i(2, "column"), t(");"),
    i(0),
  }),

  s("cte", {
    t("WITH "), i(1, "cte_name"),
    t({ " AS (", "    SELECT " }), i(2, "*"),
    t({ "", "    FROM " }), i(3, "table"),
    t({ "", "    WHERE " }), i(4, "condition"),
    t({ "", ")", "SELECT " }), i(5, "*"),
    t({ "", "FROM " }), rep(1), t(";"),
    i(0),
  }),

  s("case", {
    t({ "CASE", "    WHEN " }), i(1, "condition"), t(" THEN "), i(2, "result"),
    t({ "", "    ELSE " }), i(3, "other"),
    t({ "", "END AS " }), i(4, "alias"),
    i(0),
  }),
}
