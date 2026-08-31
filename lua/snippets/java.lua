local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local c = ls.choice_node

local function get_date()
  return os.date("%Y-%m-%d")
end

local function get_year()
  return os.date("%Y")
end

local function get_filename()
  local name = vim.fn.expand("%:t")
  return name ~= "" and name or "Untitled.java"
end

local function get_classname()
  local name = vim.fn.expand("%:t:r")
  return name ~= "" and name or "Untitled"
end

local FIELD_WIDTH = 15

local function label(text)
  return text .. string.rep(" ", math.max(1, FIELD_WIDTH - #text))
end

local function build_header(_, _)
  local nodes = {
    t({ "/**" }),
    t({ "", " * " .. label("File:") }),
    f(get_filename, {}),
    t({ "", " * " .. label("Author:") }),
    i(1, "Miquéias Medeiros"),
    t({ "", " * " .. label("Created:") }),
    f(get_date, {}),
    t({ "", " * " .. label("Modified:") }),
    f(get_date, {}),
    t({ "", " *", " * " .. label("Description:") }),
    t({ "", " *     " }),
    i(2, "Longer description, if needed."),
    t({ "", " *", " * " .. label("Problem Statement:") }),
    t({ "", " *     " }),
    i(3, "Paste the exercise/assignment text here."),
    t({ "", " *", " * " .. label("Usage:") }),
    t({
      "",
      " *     Compile and run from the directory containing this file.",
      " *",
      " *     $ javac ",
    }),
    f(get_filename, {}),
    t({ "", " *     $ java " }),
    f(get_classname, {}),
    t({ "", " *", " * " .. label("References:") }),
    t({ "", " *     - " }),
    i(4, "https://..."),
    t({ "", " *", " * SPDX-License-Identifier: MIT" }),
    t({ "", " * " .. label("Copyright:") }),
    t("\194\169 "),
    f(get_year, {}),
    t(" All rights reserved."),
    t({ "", " */", "" }),
    i(0),
  }

  return sn(nil, nodes)
end

local function build_sol_with_header(_, _)
  local nodes = {
    d(1, build_header, {}),
    t({ "", "", "public class " }),
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
    end, { 3 }),
    t("("),
    i(6, "/* args */"),
    t("));"),
    t({
      "",
      "    }",
      "}",
      "",
      "class Solution {",
      "    public ",
    }),
    i(2, "int"),
    t(" "),
    i(3, "solve"),
    t("("),
    i(4, "int[] nums"),
    t({ ") {", "        " }),
    i(5, "// TODO: implement"),
    t({ "", "    }", "}" }),
    i(0),
  }

  return sn(nil, nodes)
end

return {
  -- Control flow

  s("if", {
    t("if ("),
    i(1, "condition"),
    t({ ") {", "    " }),
    i(2),
    t({ "", "}" }),
  }),

  s("ife", {
    t("if ("),
    i(1, "condition"),
    t({ ") {", "    " }),
    i(2),
    t({ "", "} else {", "    " }),
    i(3),
    t({ "", "}" }),
  }),

  s("ifel", {
    t("if ("),
    i(1, "condition"),
    t({ ") {", "    " }),
    i(2),
    t({ "", "} else if (" }),
    i(3, "condition"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "} else {", "    " }),
    i(5),
    t({ "", "}" }),
  }),

  s("for", {
    t("for (int "),
    i(1, "i"),
    t(" = 0; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" < "),
    i(2, "n"),
    t("; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("++) {"),
    t({ "", "    " }),
    i(3),
    t({ "", "}" }),
  }),

  s("fore", {
    t("for ("),
    i(1, "Type"),
    t(" "),
    i(2, "item"),
    t(" : "),
    i(3, "iterable"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  s("foreach", {
    t("for ("),
    i(1, "Type"),
    t(" "),
    i(2, "item"),
    t(" : "),
    i(3, "iterable"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  s("while", {
    t("while ("),
    i(1, "condition"),
    t({ ") {", "    " }),
    i(2),
    t({ "", "}" }),
  }),

  s("dowhile", {
    t({ "do {", "    " }),
    i(1),
    t({ "", "} while (" }),
    i(2, "condition"),
    t(");"),
  }),

  s("switch", {
    t("switch ("),
    i(1, "expression"),
    t({ ") {", "    case " }),
    i(2, "value"),
    t({ ":", "        " }),
    i(3),
    t({ "", "        break;", "    default:", "        " }),
    i(4),
    t({ "", "}" }),
  }),

  s("switche", {
    t("var result = switch ("),
    i(1, "value"),
    t({ ") {", "    case " }),
    i(2, "value"),
    t(" -> "),
    i(3, "result"),
    t({ ";", "    case " }),
    i(4, "value"),
    t(" -> "),
    i(5, "result"),
    t({ ";", "    default -> " }),
    i(6, "defaultValue"),
    t({ ";", "};" }),
  }),

  s("case", {
    t("case "),
    i(1, "value"),
    t(" -> "),
    i(2, "result"),
    t(";"),
  }),

  s("break", {
    t("break;"),
  }),

  s("continue", {
    t("continue;"),
  }),

  -- Pattern matching

  s("instanceof", {
    t("if ("),
    i(1, "object"),
    t(" instanceof "),
    i(2, "Type"),
    t(" "),
    i(3, "value"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  -- Error handling

  s("try", {
    t({ "try {", "    " }),
    i(1),
    t({ "", "} catch (" }),
    i(2, "Exception"),
    t(" "),
    i(3, "e"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  s("tryf", {
    t({ "try {", "    " }),
    i(1),
    t({ "", "} catch (" }),
    i(2, "Exception"),
    t(" "),
    i(3, "e"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "} finally {", "    " }),
    i(5),
    t({ "", "}" }),
  }),

  s("tryr", {
    t("try ("),
    i(1, "Resource resource = new Resource()"),
    t({ ") {", "    " }),
    i(2),
    t({ "", "} catch (" }),
    i(3, "Exception"),
    t(" "),
    i(4, "e"),
    t({ ") {", "    " }),
    i(5),
    t({ "", "}" }),
  }),

  s("throw", {
    t("throw new "),
    i(1, "RuntimeException"),
    t("("),
    i(2, "message"),
    t(");"),
  }),

  s("throws", {
    t("throws "),
    i(1, "Exception"),
  }),

  s("assert", {
    t("assert "),
    i(1, "condition"),
    t(" : "),
    i(2, "message"),
    t(";"),
  }),

  -- Classes and interfaces

  s("class", {
    t("public class "),
    f(get_classname, {}),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("classe", {
    t("public class "),
    i(1, "ClassName"),
    t(" extends "),
    i(2, "BaseClass"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("impl", {
    t("public class "),
    i(1, "ClassName"),
    t(" implements "),
    i(2, "InterfaceName"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("extend", {
    t("public class "),
    i(1, "ClassName"),
    t(" extends "),
    i(2, "BaseClass"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("iface", {
    t("public interface "),
    i(1, "InterfaceName"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("enum", {
    t("public enum "),
    i(1, "EnumName"),
    t({ " {", "    " }),
    i(2, "VALUE_ONE"),
    t(", "),
    i(3, "VALUE_TWO"),
    t({ ";", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("record", {
    t("public record "),
    i(1, "RecordName"),
    t("("),
    i(2, "Type field"),
    t({ ") {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("recorddto", {
    t("public record "),
    i(1, "UserResponse"),
    t({
      "(",
      "    ",
    }),
    i(2, "UUID id"),
    t({
      ",",
      "    ",
    }),
    i(3, "String name"),
    t({
      ",",
      "    ",
    }),
    i(4, "String email"),
    t({
      "",
      ") {}",
    }),
  }),

  s("sealed", {
    t("public sealed interface "),
    i(1, "InterfaceName"),
    t({ "", "    permits " }),
    i(2, "Implementation"),
    t({ " {", "}" }),
  }),

  s("sealedclass", {
    t("public sealed class "),
    i(1, "ClassName"),
    t(" permits "),
    i(2, "Implementation"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("finalclass", {
    t("public final class "),
    i(1, "ClassName"),
    t(" implements "),
    i(2, "InterfaceName"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  -- Constructors

  s("ctor", {
    t("public "),
    f(get_classname, {}),
    t("("),
    i(1),
    t({ ") {", "    " }),
    i(2),
    t({ "", "}" }),
  }),

  s("consempty", {
    t("public "),
    f(get_classname, {}),
    t("() {"),
    t({ "", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  -- Methods

  s("fn", {
    t("public "),
    i(1, "void"),
    t(" "),
    i(2, "methodName"),
    t("("),
    i(3),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  s("sfn", {
    t("public static "),
    i(1, "void"),
    t(" "),
    i(2, "methodName"),
    t("("),
    i(3),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  s("get", {
    t("public "),
    i(1, "Type"),
    t(" get"),
    i(2, "Name"),
    t({ "() {", "    return " }),
    i(3, "field"),
    t(";"),
    t({ "", "}" }),
  }),

  s("set", {
    t("public void set"),
    i(1, "Name"),
    t("("),
    i(2, "Type"),
    t(" "),
    i(3, "value"),
    t({ ") {", "    this." }),
    i(4, "field"),
    t(" = "),
    f(function(args)
      return args[1][1]
    end, { 3 }),
    t(";"),
    t({ "", "}" }),
  }),

  s("ovr", {
    t({ "@Override", "public " }),
    i(1, "void"),
    t(" "),
    i(2, "methodName"),
    t("("),
    i(3),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  -- Modifiers and fields

  s("field", {
    i(1, "private"),
    t(" "),
    i(2, "final"),
    t(" "),
    i(3, "Type"),
    t(" "),
    i(4, "field"),
    t(";"),
  }),

  s("pf", {
    t("private final "),
    i(1, "Type"),
    t(" "),
    i(2, "field"),
    t(";"),
  }),

  s("pr", {
    t("private "),
    i(1, "Type"),
    t(" "),
    i(2, "field"),
    t(";"),
  }),

  s("st", {
    t("static "),
    i(1, "Type"),
    t(" "),
    i(2, "field"),
    t(";"),
  }),

  s("psf", {
    t("public static final "),
    i(1, "Type"),
    t(" "),
    i(2, "CONSTANT"),
    t(" = "),
    i(3, "value"),
    t(";"),
  }),

  s("staticfinal", {
    t("private static final "),
    i(1, "Type"),
    t(" "),
    i(2, "CONSTANT"),
    t(" = "),
    i(3, "value"),
    t(";"),
  }),

  -- Common patterns

  s("main", {
    t({ "public static void main(String[] args) {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("psvm", {
    t({ "public static void main(String[] args) {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("var", {
    t("var "),
    i(1, "name"),
    t(" = "),
    i(2, "expression"),
    t(";"),
  }),

  s("new", {
    i(1, "Type"),
    t(" "),
    i(2, "name"),
    t(" = new "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("("),
    i(3),
    t(");"),
  }),

  s("newobj", {
    t("var "),
    i(1, "name"),
    t(" = new "),
    i(2, "Type"),
    t("("),
    i(3),
    t(");"),
  }),

  s("arraylist", {
    t("List<"),
    i(1, "Type"),
    t("> "),
    i(2, "list"),
    t(" = new ArrayList<>();"),
  }),

  s("hashmap", {
    t("Map<"),
    i(1, "KeyType"),
    t(", "),
    i(2, "ValueType"),
    t("> "),
    i(3, "map"),
    t(" = new HashMap<>();"),
  }),

  s("hashset", {
    t("Set<"),
    i(1, "Type"),
    t("> "),
    i(2, "set"),
    t(" = new HashSet<>();"),
  }),

  s("array", {
    i(1, "int"),
    t("[] "),
    i(2, "array"),
    t(" = new "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("["),
    i(3, "size"),
    t("];"),
  }),

  s("listof", {
    t("List.of("),
    i(1, "value"),
    t(")"),
  }),

  s("mapof", {
    t("Map.of("),
    i(1, "key"),
    t(", "),
    i(2, "value"),
    t(")"),
  }),

  s("setof", {
    t("Set.of("),
    i(1, "value"),
    t(")"),
  }),

  -- Lambdas and functional interfaces

  s("lambda", {
    t("("),
    i(1, "x"),
    t(") -> "),
    i(2, "expression"),
  }),

  s("supplier", {
    t("Supplier<"),
    i(1, "Type"),
    t("> "),
    i(2, "supplier"),
    t(" = () -> "),
    i(3, "expression"),
    t(";"),
  }),

  s("consumer", {
    t("Consumer<"),
    i(1, "Type"),
    t("> "),
    i(2, "consumer"),
    t(" = "),
    i(3, "x"),
    t(" -> "),
    i(4, "statement"),
    t(";"),
  }),

  s("function", {
    t("Function<"),
    i(1, "InType"),
    t(", "),
    i(2, "OutType"),
    t("> "),
    i(3, "function"),
    t(" = "),
    i(4, "x"),
    t(" -> "),
    i(5, "expression"),
    t(";"),
  }),

  s("predicate", {
    t("Predicate<"),
    i(1, "Type"),
    t("> "),
    i(2, "predicate"),
    t(" = "),
    i(3, "x"),
    t(" -> "),
    i(4, "condition"),
    t(";"),
  }),

  -- Collections and streams

  s("stream", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .filter(" }),
    i(2, "x"),
    t(" -> "),
    i(3, "condition"),
    t(")"),
    t({ "", "    .collect(Collectors.toList());" }),
  }),

  s("streammap", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .map(" }),
    i(2, "x"),
    t(" -> "),
    i(3, "expression"),
    t(")"),
    t({ "", "    .collect(Collectors.toList());" }),
  }),

  s("streamfilter", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .filter(" }),
    i(2, "x"),
    t(" -> "),
    i(3, "condition"),
    t(")"),
    t({ "", "    .toList();" }),
  }),

  s("streamfind", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .filter(" }),
    i(2, "x"),
    t(" -> "),
    i(3, "condition"),
    t(")"),
    t({ "", "    .findFirst()" }),
    t({ "", "    .orElseThrow();" }),
  }),

  s("streamreduce", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .reduce(" }),
    i(2, "identity"),
    t(", ("),
    i(3, "a"),
    t(", "),
    i(4, "b"),
    t(") -> "),
    i(5, "a + b"),
    t(");"),
  }),

  s("streamgroup", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .collect(Collectors.groupingBy(" }),
    i(2, "x"),
    t(" -> "),
    i(3, "x.getKey()"),
    t("));"),
  }),

  s("streamsorted", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .sorted(Comparator.comparing(" }),
    i(2, "x"),
    t(" -> "),
    i(3, "x.getField()"),
    t("))"),
    t({ "", "    .toList();" }),
  }),

  s("streamjoin", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .map(" }),
    i(2, "Object::toString"),
    t(")"),
    t({ "", '    .collect(Collectors.joining(", "));' }),
  }),

  s("streamcount", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .count();" }),
  }),

  s("streamany", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .anyMatch(" }),
    i(2, "x"),
    t(" -> "),
    i(3, "condition"),
    t(");"),
  }),

  s("streamall", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .allMatch(" }),
    i(2, "x"),
    t(" -> "),
    i(3, "condition"),
    t(");"),
  }),

  s("streamnone", {
    i(1, "collection"),
    t(".stream()"),
    t({ "", "    .noneMatch(" }),
    i(2, "x"),
    t(" -> "),
    i(3, "condition"),
    t(");"),
  }),

  s("intstream", {
    t("IntStream.range("),
    i(1, "0"),
    t(", "),
    i(2, "n"),
    t(")"),
    t({ "", "    .forEach(" }),
    i(3, "i"),
    t(" -> "),
    i(4),
    t(");"),
  }),

  -- Optional

  s("opt", {
    t("Optional<"),
    i(1, "Type"),
    t("> "),
    i(2, "optional"),
    t(" = Optional.ofNullable("),
    i(3, "value"),
    t(");"),
  }),

  s("optmap", {
    i(1, "optional"),
    t(".map("),
    i(2, "x"),
    t(" -> "),
    i(3, "expression"),
    t(")"),
    t({ "", "    .orElse(" }),
    i(4, "defaultValue"),
    t(");"),
  }),

  s("orelse", {
    i(1, "optional"),
    t(".orElse("),
    i(2, "defaultValue"),
    t(")"),
  }),

  s("orelsethrow", {
    i(1, "optional"),
    t(".orElseThrow(() -> new "),
    i(2, "Exception"),
    t("("),
    i(3, "message"),
    t("));"),
  }),

  s("ifpresent", {
    i(1, "optional"),
    t(".ifPresent("),
    i(2, "value"),
    t(" -> "),
    i(3, "statement"),
    t(");"),
  }),

  -- UUID

  s("uuid", {
    t("UUID "),
    i(1, "id"),
    t(" = UUID.randomUUID();"),
  }),

  s("uuidfield", {
    t("private UUID "),
    i(1, "id"),
    t(";"),
  }),

  -- Imports

  s("imp", {
    t("import "),
    i(1, "package.Class"),
    t(";"),
  }),

  s("impa", {
    t("import "),
    i(1, "package"),
    t(".*;"),
  }),

  s("pkg", {
    t("package "),
    i(1, "com.example"),
    t(";"),
  }),

  -- Debugging

  s("sout", {
    t("System.out.println("),
    i(1),
    t(");"),
  }),

  s("souf", {
    t('System.out.printf("'),
    i(1, "%s"),
    t('", '),
    i(2, "value"),
    t(");"),
  }),

  s("debug", {
    t('System.out.println("'),
    i(1, "variable"),
    t(' = " + '),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(");"),
  }),

  s("serr", {
    t("System.err.println("),
    i(1),
    t(");"),
  }),

  -- Object methods

  s("tostring", {
    t({ "@Override", "public String toString() {" }),
    t({ "", '    return "' }),
    f(get_classname, {}),
    t('{" +'),
    t({ "", '            "' }),
    i(1, "field"),
    t('=" + '),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" +"),
    t({ "", '            "}";' }),
    t({ "", "}" }),
  }),

  s("equals", {
    t({ "@Override", "public boolean equals(Object o) {" }),
    t({ "", "    if (this == o) return true;" }),
    t({ "", "    if (o == null || getClass() != o.getClass()) return false;" }),
    t({ "", "    " }),
    f(get_classname, {}),
    t(" that = ("),
    f(get_classname, {}),
    t(") o;"),
    t({ "", "    return Objects.equals(" }),
    i(1, "field"),
    t(", that."),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(");"),
    t({ "", "}" }),
  }),

  s("hashcode", {
    t({ "@Override", "public int hashCode() {" }),
    t({ "", "    return Objects.hash(" }),
    i(1, "field"),
    t(");"),
    t({ "", "}" }),
  }),

  -- Lombok

  s("ldata", {
    t("@Data"),
  }),

  s("lgetter", {
    t("@Getter"),
  }),

  s("lsetter", {
    t("@Setter"),
  }),

  s("lnoargs", {
    t("@NoArgsConstructor"),
  }),

  s("lallargs", {
    t("@AllArgsConstructor"),
  }),

  s("lrequiredargs", {
    t("@RequiredArgsConstructor"),
  }),

  s("lbuilder", {
    t("@Builder"),
  }),

  s("ltostring", {
    t("@ToString"),
  }),

  s("leq", {
    t("@EqualsAndHashCode"),
  }),

  s("lslf4j", {
    t("@Slf4j"),
  }),

  s("lclass", {
    t({
      "@Data",
      "@Builder",
      "@NoArgsConstructor",
      "@AllArgsConstructor",
      "public class ",
    }),
    i(1, "ClassName"),
    t({ " {", "    private " }),
    i(2, "Type"),
    t(" "),
    i(3, "field"),
    t(";"),
    t({ "", "", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  -- Spring Boot

  s("sbapp", {
    t({
      "@SpringBootApplication",
      "public class ",
    }),
    f(get_classname, {}),
    t({ " {", "", "    public static void main(String[] args) {" }),
    t({ "", "        SpringApplication.run(" }),
    f(get_classname, {}),
    t(".class, args);"),
    t({ "", "    }", "", "}" }),
  }),

  s("restcontroller", {
    t({
      "@RestController",
      '@RequestMapping("',
    }),
    i(1, "/api"),
    t({ '")', "public class " }),
    i(2, "ClassName"),
    t(" {"),
    t({ "", "", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("service", {
    t({ "@Service", "public class " }),
    i(1, "ClassName"),
    t(" {"),
    t({ "", "", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("repository", {
    t({ "@Repository", "public interface " }),
    i(1, "ClassName"),
    t("Repository extends JpaRepository<"),
    i(2, "Entity"),
    t(", "),
    i(3, "UUID"),
    t({ "> {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("component", {
    t("@Component"),
  }),

  s("configuration", {
    t({ "@Configuration", "public class " }),
    i(1, "ClassName"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("bean", {
    t("@Bean"),
    t({ "", "public " }),
    i(1, "Type"),
    t(" "),
    i(2, "beanName"),
    t("() {"),
    t({ "", "    return new " }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("();"),
    t({ "", "}" }),
  }),

  s("transactional", {
    t("@Transactional"),
  }),

  s("validated", {
    t("@Validated"),
  }),

  s("valid", {
    t("@Valid "),
    i(1, "Type"),
    t(" "),
    i(2, "request"),
  }),

  s("getmapping", {
    t('@GetMapping("'),
    i(1, "/path"),
    t('")'),
    t({ "", "public " }),
    i(2, "ResponseEntity<?>"),
    t(" "),
    i(3, "methodName"),
    t("("),
    i(4),
    t({ ") {", "    " }),
    i(5),
    t({ "", "}" }),
  }),

  s("postmapping", {
    t('@PostMapping("'),
    i(1, "/path"),
    t('")'),
    t({ "", "public " }),
    i(2, "ResponseEntity<?>"),
    t(" "),
    i(3, "methodName"),
    t("(@RequestBody "),
    i(4, "Type body"),
    t({ ") {", "    " }),
    i(5),
    t({ "", "}" }),
  }),

  s("putmapping", {
    t('@PutMapping("'),
    i(1, "/path/{id}"),
    t('")'),
    t({ "", "public " }),
    i(2, "ResponseEntity<?>"),
    t(" "),
    i(3, "methodName"),
    t("(@PathVariable "),
    i(4, "UUID id"),
    t(", @RequestBody "),
    i(5, "Type body"),
    t({ ") {", "    " }),
    i(6),
    t({ "", "}" }),
  }),

  s("patchmapping", {
    t('@PatchMapping("'),
    i(1, "/path/{id}"),
    t('")'),
    t({ "", "public " }),
    i(2, "ResponseEntity<?>"),
    t(" "),
    i(3, "methodName"),
    t("(@PathVariable "),
    i(4, "UUID id"),
    t(", @RequestBody "),
    i(5, "Type body"),
    t({ ") {", "    " }),
    i(6),
    t({ "", "}" }),
  }),

  s("deletemapping", {
    t('@DeleteMapping("'),
    i(1, "/path/{id}"),
    t('")'),
    t({ "", "public " }),
    i(2, "ResponseEntity<?>"),
    t(" "),
    i(3, "methodName"),
    t("(@PathVariable "),
    i(4, "UUID id"),
    t({ ") {", "    " }),
    i(5),
    t({ "", "}" }),
  }),

  s("pathvar", {
    t("@PathVariable "),
    i(1, "UUID"),
    t(" "),
    i(2, "id"),
  }),

  s("reqbody", {
    t("@RequestBody "),
    i(1, "Type"),
    t(" "),
    i(2, "request"),
  }),

  s("reqparam", {
    t("@RequestParam "),
    i(1, "Type"),
    t(" "),
    i(2, "value"),
  }),

  s("requestparam", {
    t('@RequestParam(name = "'),
    i(1, "name"),
    t('") '),
    i(2, "Type"),
    t(" "),
    i(3, "value"),
  }),

  s("response", {
    t("ResponseEntity."),
    c(1, {
      t("ok(body)"),
      t("status(HttpStatus.CREATED).body(body)"),
      t("noContent().build()"),
      t("notFound().build()"),
      t("badRequest().build()"),
    }),
  }),

  s("ok", {
    t("return ResponseEntity.ok("),
    i(1, "response"),
    t(");"),
  }),

  s("created", {
    t("return ResponseEntity.status(HttpStatus.CREATED).body("),
    i(1, "response"),
    t(");"),
  }),

  s("nocontent", {
    t("return ResponseEntity.noContent().build();"),
  }),

  s("notfound", {
    t("return ResponseEntity.notFound().build();"),
  }),

  -- JPA

  s("entity", {
    t({
      "@Entity",
      '@Table(name = "',
    }),
    i(1, "table_name"),
    t({ '")', "public class " }),
    i(2, "ClassName"),
    t({
      " {",
      "",
      "    @Id",
      "    @GeneratedValue(strategy = GenerationType.UUID)",
      "    private UUID id;",
      "",
      "    ",
    }),
    i(0),
    t({ "", "}" }),
  }),

  s("column", {
    t('@Column(name = "'),
    i(1, "column_name"),
    t('")'),
  }),

  s("onetoone", {
    t({
      "@OneToOne",
      '@JoinColumn(name = "',
    }),
    i(1, "entity_id"),
    t({ '")', "private " }),
    i(2, "Entity"),
    t(" "),
    i(3, "entity"),
    t(";"),
  }),

  s("manytoone", {
    t({
      "@ManyToOne",
      '@JoinColumn(name = "',
    }),
    i(1, "entity_id"),
    t({ '")', "private " }),
    i(2, "Entity"),
    t(" "),
    i(3, "entity"),
    t(";"),
  }),

  s("onetomany", {
    t({
      "@OneToMany(",
      "    mappedBy = \"",
    }),
    i(1, "parent"),
    t({
      "\",",
      "    cascade = CascadeType.ALL,",
      "    orphanRemoval = true",
      ")",
      "private List<",
    }),
    i(2, "Entity"),
    t("> "),
    i(3, "entities"),
    t(" = new ArrayList<>();"),
  }),

  s("manytomany", {
    t({
      "@ManyToMany",
      "private List<",
    }),
    i(1, "Entity"),
    t("> "),
    i(2, "entities"),
    t(" = new ArrayList<>();"),
  }),

  s("embedded", {
    t("@Embedded"),
    t({ "", "private " }),
    i(1, "Type"),
    t(" "),
    i(2, "value"),
    t(";"),
  }),

  s("embeddable", {
    t({
      "@Embeddable",
      "public class ",
    }),
    i(1, "ClassName"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  -- Exception handling

  s("controlleradvice", {
    t({
      "@RestControllerAdvice",
      "public class ",
    }),
    i(1, "GlobalExceptionHandler"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("exceptionhandler", {
    t("@ExceptionHandler("),
    i(1, "SomeException.class"),
    t({ ")", "public ResponseEntity<" }),
    i(2, "ErrorResponse"),
    t("> handle("),
    i(3, "SomeException exception"),
    t({ ") {", "    return ResponseEntity.status(" }),
    i(4, "HttpStatus.NOT_FOUND"),
    t(").body("),
    i(5, "response"),
    t({ ");", "}" }),
  }),

  s("customexception", {
    t("public class "),
    i(1, "CustomException"),
    t(" extends "),
    i(2, "RuntimeException"),
    t({ " {", "", "    public " }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("(String message) {"),
    t({ "", "        super(message);", "    }", "}" }),
  }),

  -- Builder

  s("builder", {
    t("var "),
    i(1, "object"),
    t(" = "),
    i(2, "Type"),
    t({
      ".builder()",
      "    .",
    }),
    i(3, "field"),
    t("("),
    i(4, "value"),
    t(")"),
    t({
      "    .",
    }),
    i(5, "field"),
    t("("),
    i(6, "value"),
    t(")"),
    t({
      "    .build();",
    }),
  }),

  -- Tests

  s("test", {
    t({ "@Test", "void test" }),
    i(1, "Name"),
    t({ "() {", "    " }),
    i(2),
    t({ "", "}" }),
  }),

  s("beforeeach", {
    t({ "@BeforeEach", "void setUp() {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("aftereach", {
    t({ "@AfterEach", "void tearDown() {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("asserteq", {
    t("assertEquals("),
    i(1, "expected"),
    t(", "),
    i(2, "actual"),
    t(");"),
  }),

  s("asserttrue", {
    t("assertTrue("),
    i(1, "condition"),
    t(");"),
  }),

  s("assertfalse", {
    t("assertFalse("),
    i(1, "condition"),
    t(");"),
  }),

  s("assertnull", {
    t("assertNull("),
    i(1, "value"),
    t(");"),
  }),

  s("assertnotnull", {
    t("assertNotNull("),
    i(1, "value"),
    t(");"),
  }),

  s("assertthrows", {
    t("assertThrows("),
    i(1, "Exception.class"),
    t(", () -> "),
    i(2, "method()"),
    t(");"),
  }),

  s("assertall", {
    t({
      "assertAll(",
      "    ",
    }),
    i(1, "assertEquals(expected1, actual1)"),
    t({ ",", "    " }),
    i(2, "assertEquals(expected2, actual2)"),
    t({ ",", "    " }),
    i(3, "assertTrue(condition)"),
    t({ "", ");" }),
  }),

  -- Mockito

  s("mock", {
    t("@Mock"),
    t({ "", "private " }),
    i(1, "Repository"),
    t(" "),
    i(2, "repository"),
    t(";"),
  }),

  s("injectmocks", {
    t("@InjectMocks"),
    t({ "", "private " }),
    i(1, "Service"),
    t(" "),
    i(2, "service"),
    t(";"),
  }),

  s("spy", {
    t("@Spy"),
    t({ "", "private " }),
    i(1, "Type"),
    t(" "),
    i(2, "object"),
    t(";"),
  }),

  s("when", {
    t("when("),
    i(1, "repository.findById(id)"),
    t({ ")", "    .thenReturn(" }),
    i(2, "Optional.of(entity)"),
    t(");"),
  }),

  s("whenvoid", {
    t("doNothing().when("),
    i(1, "repository"),
    t(")."),
    i(2, "method()"),
    t(";"),
  }),

  s("verify", {
    t("verify("),
    i(1, "repository"),
    t(")."),
    i(2, "method()"),
    t(";"),
  }),

  s("verifytimes", {
    t("verify("),
    i(1, "repository"),
    t(", times("),
    i(2, "1"),
    t("))."),
    i(3, "method()"),
    t(";"),
  }),

  s("verifynever", {
    t("verify("),
    i(1, "repository"),
    t(", never())."),
    i(2, "method()"),
    t(";"),
  }),

  s("argumentcaptor", {
    t({
      "@Captor",
      "ArgumentCaptor<",
    }),
    i(1, "Type"),
    t("> "),
    i(2, "captor"),
    t(";"),
  }),

  -- Spring tests

  s("springtest", {
    t({
      "@SpringBootTest",
      "class ",
    }),
    i(1, "ClassName"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  s("webmvctest", {
    t({
      "@WebMvcTest(",
    }),
    i(1, "Controller.class"),
    t({ ")", "class " }),
    i(2, "ControllerTest"),
    t({ " {", "    " }),
    i(0),
    t({ "", "}" }),
  }),

  -- Text blocks

  s("textblock", {
    t("String "),
    i(1, "text"),
    t({
      ' = """',
      "",
    }),
    i(2, "text"),
    t({
      "",
      '""";',
    }),
  }),

  -- Comments

  s("//", {
    t("// "),
    i(0),
  }),

  s("/*", {
    t({ "/*", " * " }),
    i(0),
    t({ "", " */" }),
  }),

  s("todo", {
    t("// TODO: "),
    i(0),
  }),

  s("fixme", {
    t("// FIXME: "),
    i(0),
  }),

  s("jdoc", {
    t({ "/**", " * " }),
    i(1, "Short description."),
    t({ "", " *" }),
    t({ "", " * @param " }),
    i(2, "paramName"),
    t(" "),
    i(3, "description"),
    t({ "", " * @return " }),
    i(4, "description"),
    t({ "", " */" }),
  }),

  -- File header

  s("exs", {
    d(1, build_header, {}),
  }),

  -- Solution scaffolding

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

  s("soldc", {
    d(1, build_sol_with_header, {}),
  }),
}
