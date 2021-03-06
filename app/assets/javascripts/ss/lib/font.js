this.SS_Font = (function () {
  function SS_Font() {
  }

  SS_Font.size = null; //%

  SS_Font.render = function () {
    var vr;
    this.size = parseInt(Cookies.get("ss-font")) || 100;
    if (this.size !== 100) {
      this.set(this.size);
    }
    vr = $("#ss-medium");
    vr.html('<a href="#" onclick="return SS_Font.set(100)">' + vr.html() + '</a>');
    vr = $("#ss-small");
    vr.html('<a href="#" onclick="return SS_Font.set(false)">' + vr.html() + '</a>');
    vr = $("#ss-large");
    return vr.html('<a href="#" onclick="return SS_Font.set(true)">' + vr.html() + '</a>');
  };

  SS_Font.set = function (size) {
    if (size === true) {
      size = this.size + 20;
      if (size > 200) {
        return false;
      }
    } else if (size === false) {
      size = this.size - 20;
      if (size < 60) {
        return false;
      }
    }
    this.size = size;
    $("body").css("font-size", size + "%");
    Cookies.set("ss-font", size, {
      expires: 7,
      path: '/'
    });
    return false;
  };

  return SS_Font;

})();

// ---
// generated by coffee-script 1.9.2