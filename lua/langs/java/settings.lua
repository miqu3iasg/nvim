-- lua/langs/java/settings.lua

return {
  java = {
    signatureHelp = { enabled = true },
    contentProvider = { preferred = "fernflower" },
    completion = {
      favoriteStaticMembers = {
        "org.junit.jupiter.api.Assertions.*",
        "org.mockito.Mockito.*",
        "java.util.Objects.requireNonNull",
      },
    },
    sources = {
      organizeImports = {
        starThreshold = 9999,
        staticStarThreshold = 9999,
      },
    },
    configuration = {
      updateBuildConfiguration = "interactive",

      -- Uncomment and adjust the paths if you switch between JDK versions
      -- (e.g. a legacy project on 17, a newer one on 21). jdtls picks the
      -- right runtime per project based on pom.xml/build.gradle. Left
      -- commented on purpose: wrong paths here break jdtls startup.
      -- runtimes = {
      --   { name = "JavaSE-17", path = "/usr/lib/jvm/java-17-openjdk" },
      --   { name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk", default = true },
      -- },
    },
    format = {
      enabled = true,
      comments = {
        enabled = false,
      },
    },
  },
}
