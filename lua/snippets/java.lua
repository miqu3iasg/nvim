-- lua/snippets/java.lua

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node

-- Helpers

-- Name of the current file without extension, used as the class name
local function get_classname()
	local name = vim.fn.expand("%:t:r")
	return name ~= "" and name or "Untitled"
end

-- Date in ISO format, used in @since
local function today()
	return os.date("%Y-%m-%d")
end

-- Uppercases the first letter of the first argument (getter/setter names)
local function capitalize(args)
	local str = args[1][1] or ""
	return str:sub(1, 1):upper() .. str:sub(2)
end

-- Repeats the text of another insert node
local function mirror(idx)
	return f(function(args)
		return args[1][1]
	end, { idx })
end

-- Insert node whose default text is computed when the snippet expands
local function dynamic_default(pos, fn)
	return d(pos, function()
		return sn(nil, { i(1, fn()) })
	end, {})
end

-- Access modifier as an editable insert node (no choice nodes, so jumping
-- works normally). Delete the text for package-private.
-- Always follow it with with_space(pos).
local function access(pos, default)
	return i(pos, default or "public")
end

-- Optional static modifier, same idea. Follow it with with_space(pos).
local function static_choice(pos)
	return i(pos, "static")
end

-- Outputs a single space only when the referenced node is not empty,
-- so removing a modifier doesn't leave a stray space behind
local function with_space(idx)
	return f(function(args)
		local v = args[1][1] or ""
		return v ~= "" and " " or ""
	end, { idx })
end

-- Generates a method snippet with a fixed modifier
local function method(trig, modifier)
	return s(trig, {
		t(modifier .. " "),
		i(1, "void"),
		t(" "),
		i(2, "name"),
		t("("),
		i(3),
		t({ ") {", "    " }),
		i(4),
		t({ "", "}" }),
		i(0),
	})
end

-- Snippets

local snippets = {

	-- Scaffolding

	-- Solution scaffolding for practice problems (LeetCode, Kattis, etc.).
	s("sol", {
		t("public class "),
		f(get_classname, {}),
		t({
			" {",
			"",
			"    public static void main(String[] args) {",
			"        Solution sol = new Solution();",
		}),
		t({ "", "        System.out.println(sol." }),
		f(function(args)
			return args[1][1]
		end, { 2 }),
		t("("),
		i(5, "/* args */"),
		t("));"),
		t({
			"",
			"    }",
			"}",
			"",
			"class Solution {",
			"    public ",
		}),
		i(1, "int"),
		t(" "),
		i(2, "solve"),
		t("("),
		i(3, "int[] nums"),
		t({ ") {", "        " }),
		i(4, "// TODO: implement"),
		t({ "", "    }", "}" }),
		i(0),
	}),

	-- Public class named after the file, with a main method
	s("run", {
		t("public class "),
		f(get_classname, {}),
		t({ " {", "", "    public static void main(String[] args) {", "        " }),
		i(1, "// TODO"),
		t({ "", "    }", "}" }),
		i(0),
	}),

	-- Same as run, with a Scanner reading from standard input
	s("runsc", {
		t({ "import java.util.Scanner;", "", "public class " }),
		f(get_classname, {}),
		t({
			" {",
			"",
			"    public static void main(String[] args) {",
			"        Scanner sc = new Scanner(System.in);",
			"        ",
		}),
		i(1),
		t({ "", "        sc.close();", "    }", "}" }),
		i(0),
	}),

	s("main", {
		t({ "public static void main(String[] args) {", "    " }),
		i(1),
		t({ "", "}" }),
		i(0),
	}),

	-- Types

	s("class", {
		access(1),
		with_space(1),
		t("class "),
		dynamic_default(2, get_classname),
		t({ " {", "    " }),
		i(3),
		t({ "", "}" }),
		i(0),
	}),

	s("aclass", {
		access(1),
		with_space(1),
		t("abstract class "),
		i(2, "Name"),
		t({ " {", "    " }),
		i(3),
		t({ "", "}" }),
		i(0),
	}),

	s("sclass", {
		access(1),
		with_space(1),
		t("class "),
		i(2, "Child"),
		t(" extends "),
		i(3, "Parent"),
		t({ " {", "    " }),
		i(4),
		t({ "", "}" }),
		i(0),
	}),

	s("iclass", {
		access(1),
		with_space(1),
		t("class "),
		i(2, "Name"),
		t(" implements "),
		i(3, "Interface"),
		t({ " {", "    " }),
		i(4),
		t({ "", "}" }),
		i(0),
	}),

	s("iface", {
		access(1),
		with_space(1),
		t("interface "),
		i(2, "Name"),
		t({ " {", "    " }),
		i(3),
		t({ "", "}" }),
		i(0),
	}),

	s("enum", {
		access(1),
		with_space(1),
		t("enum "),
		i(2, "Name"),
		t({ " {", "    " }),
		i(3, "A, B, C"),
		t({ "", "}" }),
		i(0),
	}),

	s("rec", {
		access(1),
		with_space(1),
		t("record "),
		i(2, "Name"),
		t("("),
		i(3, "String name, int age"),
		t(") {}"),
		i(0),
	}),

	-- Members

	-- Constructor named after the file by default
	s("constr", {
		access(1),
		with_space(1),
		dynamic_default(2, get_classname),
		t("("),
		i(3),
		t({ ") {", "    " }),
		i(4),
		t({ "", "}" }),
		i(0),
	}),

	-- Method with optional access and static modifiers
	-- (delete the text of a modifier to omit it)
	s("fun", {
		access(1),
		with_space(1),
		static_choice(2),
		with_space(2),
		i(3, "void"),
		t(" "),
		i(4, "name"),
		t("("),
		i(5),
		t({ ") {", "    " }),
		i(6),
		t({ "", "}" }),
		i(0),
	}),

	-- Methods with a fixed modifier. sfun is public static
	method("pubfun", "public"),
	method("privfun", "private"),
	method("protfun", "protected"),
	method("sfun", "public static"),

	-- Field, private by default. The second stop holds "final";
	-- replace it with "static" / "static final" or delete it.
	s("field", {
		access(1, "private"),
		with_space(1),
		i(2, "final"),
		with_space(2),
		i(3, "String"),
		t(" "),
		i(4, "name"),
		t(";"),
		i(0),
	}),

	s("const", {
		access(1),
		with_space(1),
		t("static final "),
		i(2, "int"),
		t(" "),
		i(3, "CONSTANT"),
		t(" = "),
		i(4),
		t(";"),
		i(0),
	}),

	-- Private field with its getter and setter
	s("getset", {
		t("private "),
		i(1, "String"),
		t(" "),
		i(2, "name"),
		t({ ";", "", "public " }),
		mirror(1),
		t(" get"),
		f(capitalize, { 2 }),
		t({ "() {", "    return " }),
		mirror(2),
		t({ ";", "}", "", "public void set" }),
		f(capitalize, { 2 }),
		t("("),
		mirror(1),
		t(" "),
		mirror(2),
		t({ ") {", "    this." }),
		mirror(2),
		t(" = "),
		mirror(2),
		t({ ";", "}" }),
		i(0),
	}),

	s("tostring", {
		t({ "@Override", "public String toString() {", '    return "' }),
		f(get_classname, {}),
		t("{"),
		i(1),
		t({ '}";', "}" }),
		i(0),
	}),

	-- Output

	s("sout", { t("System.out.println("), i(1), t(");"), i(0) }),
	s("souf", { t('System.out.printf("'), i(1, "%s"), t('%n"'), i(2), t(");"), i(0) }),
	s("serr", { t("System.err.println("), i(1), t(");"), i(0) }),

	-- Comments

	-- Line comment
	s("cm", { t("// "), i(1, "comment"), i(0) }),

	-- Block comment
	s("cmm", {
		t({ "/*", " * " }),
		i(1, "comment"),
		t({ "", " */" }),
		i(0),
	}),

	-- Long annotation block
	s("nb", {
		t({ "/*", "", "" }),
		i(1),
		t({ "", "", "*/" }),
		i(0),
	}),

	-- Javadoc

	-- Method doc. Delete the @param/@return/@throws lines you don't need.
	s("doc", {
		t({ "/**", " * " }),
		i(1, "Description."),
		t({ "", " *", " * @param " }),
		i(2, "paramName"),
		t(" "),
		i(3, "Description."),
		t({ "", " * @param " }),
		i(4, "paramName"),
		t(" "),
		i(5, "Description."),
		t({ "", " * @return " }),
		i(6, "Description."),
		t({ "", " * @throws " }),
		i(7, "Exception"),
		t(" "),
		i(8, "When it is thrown."),
		t({ "", " */" }),
		i(0),
	}),

	-- Doc for void methods, without @return
	s("docv", {
		t({ "/**", " * " }),
		i(1, "Description."),
		t({ "", " *", " * @param " }),
		i(2, "paramName"),
		t(" "),
		i(3, "Description."),
		t({ "", " */" }),
		i(0),
	}),

	-- Class doc. @since is filled in on expansion
	s("docc", {
		t({ "/**", " * " }),
		i(1, "Description."),
		t({ "", " *", " * @author " }),
		i(2, "Miquéias Alves Medeiros"),
		t({ "", " * @version " }),
		i(3, "1.0"),
		t({ "", " * @since " }),
		dynamic_default(4, today),
		t({ "", " */" }),
		i(0),
	}),

	-- One-line doc for fields and constants
	s("docf", { t("/** "), i(1, "Description."), t(" */"), i(0) }),

	-- Inline and standalone tags
	s("link", { t("{@link "), i(1, "Class#method"), t("}"), i(0) }),
	s("code", { t("{@code "), i(1), t("}"), i(0) }),
	s("seeref", { t("@see "), i(1, "Reference"), i(0) }),

	-- Doc with @deprecated, followed by the annotation
	s("dep", {
		t({ "/**", " * " }),
		i(1, "Description."),
		t({ "", " *", " * @deprecated " }),
		i(2, "Use {@link Other} instead."),
		t({ "", " */", "@Deprecated", "" }),
		i(0),
	}),
}

return snippets
