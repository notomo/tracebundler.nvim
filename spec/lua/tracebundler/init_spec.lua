local helper = require("tracebundler.lib.testlib.helper")
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
      return require("tracebundler.testdata.test1")
    end, {
      trace = { path_filter = helper.path_filter },
    })
    assert.is_nil(err)

    package.loaded["tracebundler.testdata.test1"] = nil

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same("test1", f())
    assert.is_nil(package.loaded["tracebundler.testdata.test1"])
  end)

  it("returns chunk that can require() by omitting .init", function()
    local bundled, err = tracebundler.execute(function()
      return require("tracebundler.testdata")
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
      require("tracebundler.testdata.mutate")
      _G._tracebundler_mutated = 8888
      require("tracebundler.testdata.mutate")
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
      require("tracebundler.testdata.mutate_with_return_nil")
      _G._tracebundler_mutated = 8888
      return require("tracebundler.testdata.mutate_with_return_nil")
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
      return require("tracebundler.testdata.assign_package_loaded")
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
end)
