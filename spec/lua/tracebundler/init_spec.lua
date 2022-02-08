local helper = require("tracebundler.lib.testlib.helper")
local tracebundler = helper.require("tracebundler")

describe("execute()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns valid chunk if input fucntion is simple", function()
    local bundled, err = tracebundler.execute(function()
      return 8888
    end, {
      path_filter = helper.path_filter,
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same(8888, f())
  end)

  it("return chunk that does not use global require() even if input function lncludes require()", function()
    local bundled, err = tracebundler.execute(function()
      return require("tracebundler.testdata.test1")
    end, {
      path_filter = helper.path_filter,
    })
    assert.is_nil(err)

    package.loaded["tracebundler.testdata.test1"] = nil

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same("test1", f())
    assert.is_nil(package.loaded["tracebundler.testdata.test1"])
  end)

  it("return chunk that can require() by omitting .init", function()
    local bundled, err = tracebundler.execute(function()
      return require("tracebundler.testdata")
    end, {
      path_filter = helper.path_filter,
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same("init", f())
  end)

  it("return chunk that can emulate package.loaded", function()
    local bundled, err = tracebundler.execute(function()
      require("tracebundler.testdata.mutate")
      _G._tracebundler_mutated = 8888
      require("tracebundler.testdata.mutate")
      return _G._tracebundler_mutated
    end, {
      path_filter = helper.path_filter,
    })
    assert.is_nil(err)

    local f, load_err = loadstring(bundled)
    assert.is_nil(load_err)
    assert.is_same(8888, f())
  end)
end)
