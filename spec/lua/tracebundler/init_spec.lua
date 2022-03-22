local helper = require("tracebundler.test.helper")
local tracebundler = helper.require("tracebundler")

describe("execute()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns valid chunk if input fucntion is simple", function()
    local bundled, err = tracebundler.execute(function()
      return 8888
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same(8888, f())
  end)

  it("returns chunk that does not use global require() even if input function lncludes require()", function()
    local bundled, err = tracebundler.execute(function()
      return require("tracebundler.test.data.number")
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    package.loaded["tracebundler.test.data.number"] = nil

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same(8888, f())
    assert.is_nil(package.loaded["tracebundler.test.data.number"])
  end)

  it("returns chunk that can require() by omitting .init", function()
    local bundled, err = tracebundler.execute(function()
      return require("tracebundler.test.data")
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same("init", f())
  end)

  it("returns chunk that can emulate package.loaded with module returning non-nil value", function()
    local bundled, err = tracebundler.execute(function()
      require("tracebundler.test.data.mutate")
      _G._tracebundler_mutated = 8888
      require("tracebundler.test.data.mutate")
      return _G._tracebundler_mutated
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same(8888, f())
  end)

  it("returns chunk that can emulate package.loaded with module returning nil value", function()
    local bundled, err = tracebundler.execute(function()
      require("tracebundler.test.data.mutate_with_return_nil")
      _G._tracebundler_mutated = 8888
      return require("tracebundler.test.data.mutate_with_return_nil")
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same(true, f())
    assert.is_same(8888, _G._tracebundler_mutated)
  end)

  it("returns chunk that can emulate package.loaded with module assigning to package.loaded", function()
    local bundled, err = tracebundler.execute(function()
      return require("tracebundler.test.data.assign_package_loaded")
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same("assign_package_loaded", f())
  end)

  it("returns chunk that can emulate dofile", function()
    local path = vim.fn.tempname()
    do
      local tmp = io.open(path, "w")
      tmp:write([[return 8888]])
      tmp:close()
    end
    _G._test_path = path

    local bundled, err = tracebundler.execute(function()
      return dofile(_G._test_path)
    end, {
      trace = { path_filter = helper.path_filter },
      bundle = { enabled_file_loader = true },
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same(8888, f())

    do
      local tmp = io.open(path, "w")
      tmp:write([[return 9999]])
      tmp:close()
    end
    assert.is_same(8888, f())
  end)

  it("returns chunk that can emulate loadfile", function()
    local path = vim.fn.tempname()
    do
      local tmp = io.open(path, "w")
      tmp:write([[return 8888]])
      tmp:close()
    end
    _G._test_path = path

    local bundled, err = tracebundler.execute(function()
      return loadfile(_G._test_path)()
    end, {
      trace = { path_filter = helper.path_filter },
      bundle = { enabled_file_loader = true },
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same(8888, f())

    do
      local tmp = io.open(path, "w")
      tmp:write([[return 9999]])
      tmp:close()
    end
    assert.is_same(8888, f())
  end)

  it("can set callback for every trace", function()
    local called = false
    local _, err = tracebundler.execute(function()
      return 8888
    end, {
      trace = {
        path_filter = helper.path_filter,
        callback = function()
          called = true
        end,
      },
    })
    assert.is_nil(err)

    assert.is_true(called)
  end)

  it("returns chunk that includes vim module", function()
    local bundled, err = tracebundler.execute(function()
      return vim.split("a a", " ", true)
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same({ "a", "a" }, f())
  end)

  it("returns chunk that uses vim module", function()
    local bundled, err = tracebundler.execute(function()
      return vim.split("a a", " ", true)
    end, {
      trace = { path_filter = helper.path_filter },
      bundle = { return_table = true },
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    local bundled_tbl = f()
    assert.no.is_nil(bundled_tbl.modules["vim.shared"])

    local called = false
    bundled_tbl.modules["vim.shared"] = function()
      local M = {}
      function M.split(...)
        called = true
        return vim.split(...)
      end
      return M
    end
    assert.is_nil(load_err)
    assert.is_same({ "a", "a" }, bundled_tbl.execute())
    assert.is_true(called)
  end)
end)

describe("bundle()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can bundle traces from callback argument", function()
    local bundled_by_callback
    local bundled, err = tracebundler.execute(function()
      return 8888
    end, {
      trace = {
        path_filter = helper.path_filter,
        callback = function(traces)
          bundled_by_callback = tracebundler.bundle(traces)
        end,
      },
    })
    assert.is_nil(err)
    assert.is_same(bundled, bundled_by_callback)

    local f, load_err = loadstring(bundled_by_callback)
    assert.is_nil(load_err)
    assert.is_same(8888, f())
  end)

  it("adds marker to traced line", function()
    local bundled, err = tracebundler.execute(function()
      if false then
        return 9999
      end
      return 8888
    end, {
      trace = { path_filter = helper.path_filter },
      bundle = { traced_marker = " TEST" },
    })
    assert.is_nil(err)

    assert.matches("return 8888 %-%- TEST", bundled)
    assert.no.matches("return 9999 %-%- TEST", bundled)
  end)

  it("can disable traced marker", function()
    local bundled, err = tracebundler.execute(function()
      return 8888
    end, {
      trace = { path_filter = helper.path_filter },
      bundle = { traced_marker = "" },
    })
    assert.is_nil(err)

    assert.no.matches("return 8888 %-%- TEST", bundled)
  end)

  it("can bundle file executed by runtime command", function()
    local bundled, err = tracebundler.execute(function()
      vim.cmd([[runtime spec/lua/tracebundler/testdata/source.lua]])
      return "source"
    end, {
      trace = {
        path_filter = helper.path_filter,
      },
      bundle = {
        enabled_file_loader = true,
        traced_marker = " TEST",
      },
    })
    assert.is_nil(err)

    assert.matches("spec/lua/tracebundler/testdata/source.lua", bundled)
    assert.matches("return 8888 %-%- TEST", bundled)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same("source", f())
  end)

  it("can bundle even if non-neovim-lua file", function()
    -- use package.path ./?.lua
    local bundled, err = tracebundler.execute(function()
      return require("spec.lua.tracebundler.testdata.source")
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    do
      local f, load_err = loadstring(bundled)
      assert.is_nil(load_err)
      assert.is_same(8888, f())
    end
    do
      local f, load_err = loadstring(bundled:gsub("8888", "9999"))
      assert.is_nil(load_err)
      assert.is_same(9999, f())
    end
  end)

  it("returns chunk that can require by slash separator", function()
    local bundled, err = tracebundler.execute(function()
      return require("tracebundler/test/data/number")
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    do
      local f, load_err = loadstring(bundled)
      assert.is_nil(load_err)
      assert.is_same(8888, f())
    end
    do
      local f, load_err = loadstring(bundled:gsub("8888", "9999"))
      assert.is_nil(load_err)
      assert.is_same(9999, f())
    end
  end)
end)
