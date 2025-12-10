// Salvia SSR Bundle - Generated at 2025-12-10T02:55:45.617Z
(() => {
  // https://esm.sh/preact@10.19.3/denonext/preact.mjs
  var D;
  var a;
  var J;
  var ne;
  var C;
  var j;
  var K;
  var $;
  var Q;
  var E = {};
  var X = [];
  var oe = /acit|ex(?:s|g|n|p|$)|rph|grid|ows|mnc|ntw|ine[ch]|zoo|^ord|itera/i;
  var F = Array.isArray;
  function b(e, _2) {
    for (var t in _2) e[t] = _2[t];
    return e;
  }
  function Y(e) {
    var _2 = e.parentNode;
    _2 && _2.removeChild(e);
  }
  function re(e, _2, t) {
    var i, o2, r, l2 = {};
    for (r in _2) r == "key" ? i = _2[r] : r == "ref" ? o2 = _2[r] : l2[r] = _2[r];
    if (arguments.length > 2 && (l2.children = arguments.length > 3 ? D.call(arguments, 2) : t), typeof e == "function" && e.defaultProps != null) for (r in e.defaultProps) l2[r] === void 0 && (l2[r] = e.defaultProps[r]);
    return S(e, l2, i, o2, null);
  }
  function S(e, _2, t, i, o2) {
    var r = { type: e, props: _2, key: t, ref: i, __k: null, __: null, __b: 0, __e: null, __d: void 0, __c: null, constructor: void 0, __v: o2 ?? ++J, __i: -1, __u: 0 };
    return o2 == null && a.vnode != null && a.vnode(r), r;
  }
  function H(e) {
    return e.children;
  }
  function W(e, _2) {
    this.props = e, this.context = _2;
  }
  function P(e, _2) {
    if (_2 == null) return e.__ ? P(e.__, e.__i + 1) : null;
    for (var t; _2 < e.__k.length; _2++) if ((t = e.__k[_2]) != null && t.__e != null) return t.__e;
    return typeof e.type == "function" ? P(e) : null;
  }
  function Z(e) {
    var _2, t;
    if ((e = e.__) != null && e.__c != null) {
      for (e.__e = e.__c.base = null, _2 = 0; _2 < e.__k.length; _2++) if ((t = e.__k[_2]) != null && t.__e != null) {
        e.__e = e.__c.base = t.__e;
        break;
      }
      return Z(e);
    }
  }
  function I(e) {
    (!e.__d && (e.__d = true) && C.push(e) && !A.__r++ || j !== a.debounceRendering) && ((j = a.debounceRendering) || K)(A);
  }
  function A() {
    var e, _2, t, i, o2, r, l2, s, f;
    for (C.sort($); e = C.shift(); ) e.__d && (_2 = C.length, i = void 0, r = (o2 = (t = e).__v).__e, s = [], f = [], (l2 = t.__P) && ((i = b({}, o2)).__v = o2.__v + 1, a.vnode && a.vnode(i), B(l2, i, o2, t.__n, l2.ownerSVGElement !== void 0, 32 & o2.__u ? [r] : null, s, r ?? P(o2), !!(32 & o2.__u), f), i.__.__k[i.__i] = i, te(s, i, f), i.__e != r && Z(i)), C.length > _2 && C.sort($));
    A.__r = 0;
  }
  function ee(e, _2, t, i, o2, r, l2, s, f, u, p2) {
    var n, m2, c2, h2, k3, v2 = i && i.__k || X, d3 = _2.length;
    for (t.__d = f, ie(t, _2, v2), f = t.__d, n = 0; n < d3; n++) (c2 = t.__k[n]) != null && typeof c2 != "boolean" && typeof c2 != "function" && (m2 = c2.__i === -1 ? E : v2[c2.__i] || E, c2.__i = n, B(e, c2, m2, o2, r, l2, s, f, u, p2), h2 = c2.__e, c2.ref && m2.ref != c2.ref && (m2.ref && O(m2.ref, null, c2), p2.push(c2.ref, c2.__c || h2, c2)), k3 == null && h2 != null && (k3 = h2), 65536 & c2.__u || m2.__k === c2.__k ? f = _e(c2, f, e) : typeof c2.type == "function" && c2.__d !== void 0 ? f = c2.__d : h2 && (f = h2.nextSibling), c2.__d = void 0, c2.__u &= -196609);
    t.__d = f, t.__e = k3;
  }
  function ie(e, _2, t) {
    var i, o2, r, l2, s, f = _2.length, u = t.length, p2 = u, n = 0;
    for (e.__k = [], i = 0; i < f; i++) (o2 = e.__k[i] = (o2 = _2[i]) == null || typeof o2 == "boolean" || typeof o2 == "function" ? null : typeof o2 == "string" || typeof o2 == "number" || typeof o2 == "bigint" || o2.constructor == String ? S(null, o2, null, null, o2) : F(o2) ? S(H, { children: o2 }, null, null, null) : o2.constructor === void 0 && o2.__b > 0 ? S(o2.type, o2.props, o2.key, o2.ref ? o2.ref : null, o2.__v) : o2) != null ? (o2.__ = e, o2.__b = e.__b + 1, s = se(o2, t, l2 = i + n, p2), o2.__i = s, r = null, s !== -1 && (p2--, (r = t[s]) && (r.__u |= 131072)), r == null || r.__v === null ? (s == -1 && n--, typeof o2.type != "function" && (o2.__u |= 65536)) : s !== l2 && (s === l2 + 1 ? n++ : s > l2 ? p2 > f - l2 ? n += s - l2 : n-- : n = s < l2 && s == l2 - 1 ? s - l2 : 0, s !== i + n && (o2.__u |= 65536))) : (r = t[i]) && r.key == null && r.__e && (r.__e == e.__d && (e.__d = P(r)), R(r, r, false), t[i] = null, p2--);
    if (p2) for (i = 0; i < u; i++) (r = t[i]) != null && (131072 & r.__u) == 0 && (r.__e == e.__d && (e.__d = P(r)), R(r, r));
  }
  function _e(e, _2, t) {
    var i, o2;
    if (typeof e.type == "function") {
      for (i = e.__k, o2 = 0; i && o2 < i.length; o2++) i[o2] && (i[o2].__ = e, _2 = _e(i[o2], _2, t));
      return _2;
    }
    return e.__e != _2 && (t.insertBefore(e.__e, _2 || null), _2 = e.__e), _2 && _2.nextSibling;
  }
  function se(e, _2, t, i) {
    var o2 = e.key, r = e.type, l2 = t - 1, s = t + 1, f = _2[t];
    if (f === null || f && o2 == f.key && r === f.type) return t;
    if (i > (f != null && (131072 & f.__u) == 0 ? 1 : 0)) for (; l2 >= 0 || s < _2.length; ) {
      if (l2 >= 0) {
        if ((f = _2[l2]) && (131072 & f.__u) == 0 && o2 == f.key && r === f.type) return l2;
        l2--;
      }
      if (s < _2.length) {
        if ((f = _2[s]) && (131072 & f.__u) == 0 && o2 == f.key && r === f.type) return s;
        s++;
      }
    }
    return -1;
  }
  function z(e, _2, t) {
    _2[0] === "-" ? e.setProperty(_2, t ?? "") : e[_2] = t == null ? "" : typeof t != "number" || oe.test(_2) ? t : t + "px";
  }
  function M(e, _2, t, i, o2) {
    var r;
    e: if (_2 === "style") if (typeof t == "string") e.style.cssText = t;
    else {
      if (typeof i == "string" && (e.style.cssText = i = ""), i) for (_2 in i) t && _2 in t || z(e.style, _2, "");
      if (t) for (_2 in t) i && t[_2] === i[_2] || z(e.style, _2, t[_2]);
    }
    else if (_2[0] === "o" && _2[1] === "n") r = _2 !== (_2 = _2.replace(/(PointerCapture)$|Capture$/, "$1")), _2 = _2.toLowerCase() in e ? _2.toLowerCase().slice(2) : _2.slice(2), e.l || (e.l = {}), e.l[_2 + r] = t, t ? i ? t.u = i.u : (t.u = Date.now(), e.addEventListener(_2, r ? q : G, r)) : e.removeEventListener(_2, r ? q : G, r);
    else {
      if (o2) _2 = _2.replace(/xlink(H|:h)/, "h").replace(/sName$/, "s");
      else if (_2 !== "width" && _2 !== "height" && _2 !== "href" && _2 !== "list" && _2 !== "form" && _2 !== "tabIndex" && _2 !== "download" && _2 !== "rowSpan" && _2 !== "colSpan" && _2 !== "role" && _2 in e) try {
        e[_2] = t ?? "";
        break e;
      } catch {
      }
      typeof t == "function" || (t == null || t === false && _2[4] !== "-" ? e.removeAttribute(_2) : e.setAttribute(_2, t));
    }
  }
  function G(e) {
    var _2 = this.l[e.type + false];
    if (e.t) {
      if (e.t <= _2.u) return;
    } else e.t = Date.now();
    return _2(a.event ? a.event(e) : e);
  }
  function q(e) {
    return this.l[e.type + true](a.event ? a.event(e) : e);
  }
  function B(e, _2, t, i, o2, r, l2, s, f, u) {
    var p2, n, m2, c2, h2, k3, v2, d3, y, x3, T, w, V, U2, N2, g3 = _2.type;
    if (_2.constructor !== void 0) return null;
    128 & t.__u && (f = !!(32 & t.__u), r = [s = _2.__e = t.__e]), (p2 = a.__b) && p2(_2);
    e: if (typeof g3 == "function") try {
      if (d3 = _2.props, y = (p2 = g3.contextType) && i[p2.__c], x3 = p2 ? y ? y.props.value : p2.__ : i, t.__c ? v2 = (n = _2.__c = t.__c).__ = n.__E : ("prototype" in g3 && g3.prototype.render ? _2.__c = n = new g3(d3, x3) : (_2.__c = n = new W(d3, x3), n.constructor = g3, n.render = ce), y && y.sub(n), n.props = d3, n.state || (n.state = {}), n.context = x3, n.__n = i, m2 = n.__d = true, n.__h = [], n._sb = []), n.__s == null && (n.__s = n.state), g3.getDerivedStateFromProps != null && (n.__s == n.state && (n.__s = b({}, n.__s)), b(n.__s, g3.getDerivedStateFromProps(d3, n.__s))), c2 = n.props, h2 = n.state, n.__v = _2, m2) g3.getDerivedStateFromProps == null && n.componentWillMount != null && n.componentWillMount(), n.componentDidMount != null && n.__h.push(n.componentDidMount);
      else {
        if (g3.getDerivedStateFromProps == null && d3 !== c2 && n.componentWillReceiveProps != null && n.componentWillReceiveProps(d3, x3), !n.__e && (n.shouldComponentUpdate != null && n.shouldComponentUpdate(d3, n.__s, x3) === false || _2.__v === t.__v)) {
          for (_2.__v !== t.__v && (n.props = d3, n.state = n.__s, n.__d = false), _2.__e = t.__e, _2.__k = t.__k, _2.__k.forEach(function(L) {
            L && (L.__ = _2);
          }), T = 0; T < n._sb.length; T++) n.__h.push(n._sb[T]);
          n._sb = [], n.__h.length && l2.push(n);
          break e;
        }
        n.componentWillUpdate != null && n.componentWillUpdate(d3, n.__s, x3), n.componentDidUpdate != null && n.__h.push(function() {
          n.componentDidUpdate(c2, h2, k3);
        });
      }
      if (n.context = x3, n.props = d3, n.__P = e, n.__e = false, w = a.__r, V = 0, "prototype" in g3 && g3.prototype.render) {
        for (n.state = n.__s, n.__d = false, w && w(_2), p2 = n.render(n.props, n.state, n.context), U2 = 0; U2 < n._sb.length; U2++) n.__h.push(n._sb[U2]);
        n._sb = [];
      } else do
        n.__d = false, w && w(_2), p2 = n.render(n.props, n.state, n.context), n.state = n.__s;
      while (n.__d && ++V < 25);
      n.state = n.__s, n.getChildContext != null && (i = b(b({}, i), n.getChildContext())), m2 || n.getSnapshotBeforeUpdate == null || (k3 = n.getSnapshotBeforeUpdate(c2, h2)), ee(e, F(N2 = p2 != null && p2.type === H && p2.key == null ? p2.props.children : p2) ? N2 : [N2], _2, t, i, o2, r, l2, s, f, u), n.base = _2.__e, _2.__u &= -161, n.__h.length && l2.push(n), v2 && (n.__E = n.__ = null);
    } catch (L) {
      _2.__v = null, f || r != null ? (_2.__e = s, _2.__u |= f ? 160 : 32, r[r.indexOf(s)] = null) : (_2.__e = t.__e, _2.__k = t.__k), a.__e(L, _2, t);
    }
    else r == null && _2.__v === t.__v ? (_2.__k = t.__k, _2.__e = t.__e) : _2.__e = ue(t.__e, _2, t, i, o2, r, l2, f, u);
    (p2 = a.diffed) && p2(_2);
  }
  function te(e, _2, t) {
    _2.__d = void 0;
    for (var i = 0; i < t.length; i++) O(t[i], t[++i], t[++i]);
    a.__c && a.__c(_2, e), e.some(function(o2) {
      try {
        e = o2.__h, o2.__h = [], e.some(function(r) {
          r.call(o2);
        });
      } catch (r) {
        a.__e(r, o2.__v);
      }
    });
  }
  function ue(e, _2, t, i, o2, r, l2, s, f) {
    var u, p2, n, m2, c2, h2, k3, v2 = t.props, d3 = _2.props, y = _2.type;
    if (y === "svg" && (o2 = true), r != null) {
      for (u = 0; u < r.length; u++) if ((c2 = r[u]) && "setAttribute" in c2 == !!y && (y ? c2.localName === y : c2.nodeType === 3)) {
        e = c2, r[u] = null;
        break;
      }
    }
    if (e == null) {
      if (y === null) return document.createTextNode(d3);
      e = o2 ? document.createElementNS("http://www.w3.org/2000/svg", y) : document.createElement(y, d3.is && d3), r = null, s = false;
    }
    if (y === null) v2 === d3 || s && e.data === d3 || (e.data = d3);
    else {
      if (r = r && D.call(e.childNodes), v2 = t.props || E, !s && r != null) for (v2 = {}, u = 0; u < e.attributes.length; u++) v2[(c2 = e.attributes[u]).name] = c2.value;
      for (u in v2) c2 = v2[u], u == "children" || (u == "dangerouslySetInnerHTML" ? n = c2 : u === "key" || u in d3 || M(e, u, null, c2, o2));
      for (u in d3) c2 = d3[u], u == "children" ? m2 = c2 : u == "dangerouslySetInnerHTML" ? p2 = c2 : u == "value" ? h2 = c2 : u == "checked" ? k3 = c2 : u === "key" || s && typeof c2 != "function" || v2[u] === c2 || M(e, u, c2, v2[u], o2);
      if (p2) s || n && (p2.__html === n.__html || p2.__html === e.innerHTML) || (e.innerHTML = p2.__html), _2.__k = [];
      else if (n && (e.innerHTML = ""), ee(e, F(m2) ? m2 : [m2], _2, t, i, o2 && y !== "foreignObject", r, l2, r ? r[0] : t.__k && P(t, 0), s, f), r != null) for (u = r.length; u--; ) r[u] != null && Y(r[u]);
      s || (u = "value", h2 !== void 0 && (h2 !== e[u] || y === "progress" && !h2 || y === "option" && h2 !== v2[u]) && M(e, u, h2, v2[u], false), u = "checked", k3 !== void 0 && k3 !== e[u] && M(e, u, k3, v2[u], false));
    }
    return e;
  }
  function O(e, _2, t) {
    try {
      typeof e == "function" ? e(_2) : e.current = _2;
    } catch (i) {
      a.__e(i, t);
    }
  }
  function R(e, _2, t) {
    var i, o2;
    if (a.unmount && a.unmount(e), (i = e.ref) && (i.current && i.current !== e.__e || O(i, null, _2)), (i = e.__c) != null) {
      if (i.componentWillUnmount) try {
        i.componentWillUnmount();
      } catch (r) {
        a.__e(r, _2);
      }
      i.base = i.__P = null, e.__c = void 0;
    }
    if (i = e.__k) for (o2 = 0; o2 < i.length; o2++) i[o2] && R(i[o2], _2, t || typeof e.type != "function");
    t || e.__e == null || Y(e.__e), e.__ = e.__e = e.__d = void 0;
  }
  function ce(e, _2, t) {
    return this.constructor(e, t);
  }
  D = X.slice, a = { __e: function(e, _2, t, i) {
    for (var o2, r, l2; _2 = _2.__; ) if ((o2 = _2.__c) && !o2.__) try {
      if ((r = o2.constructor) && r.getDerivedStateFromError != null && (o2.setState(r.getDerivedStateFromError(e)), l2 = o2.__d), o2.componentDidCatch != null && (o2.componentDidCatch(e, i || {}), l2 = o2.__d), l2) return o2.__E = o2;
    } catch (s) {
      e = s;
    }
    throw e;
  } }, J = 0, ne = function(e) {
    return e != null && e.constructor == null;
  }, W.prototype.setState = function(e, _2) {
    var t;
    t = this.__s != null && this.__s !== this.state ? this.__s : this.__s = b({}, this.state), typeof e == "function" && (e = e(b({}, t), this.props)), e && b(t, e), e != null && this.__v && (_2 && this._sb.push(_2), I(this));
  }, W.prototype.forceUpdate = function(e) {
    this.__v && (this.__e = true, e && this.__h.push(e), I(this));
  }, W.prototype.render = H, C = [], K = typeof Promise == "function" ? Promise.prototype.then.bind(Promise.resolve()) : setTimeout, $ = function(e, _2) {
    return e.__v.__b - _2.__v.__b;
  }, A.__r = 0, Q = 0;

  // https://esm.sh/preact@10.19.3/denonext/hooks.mjs
  var c;
  var o;
  var H2;
  var b2;
  var v = 0;
  var x = [];
  var p = [];
  var g = a.__b;
  var A2 = a.__r;
  var C2 = a.diffed;
  var F2 = a.__c;
  var q2 = a.unmount;
  function l(_2, n) {
    a.__h && a.__h(o, _2, v || n), v = 0;
    var u = o.__H || (o.__H = { __: [], __h: [] });
    return _2 >= u.__.length && u.__.push({ __V: p }), u.__[_2];
  }
  function k(_2) {
    return v = 1, B2(U, _2);
  }
  function B2(_2, n, u) {
    var t = l(c++, 2);
    if (t.t = _2, !t.__c && (t.__ = [u ? u(n) : U(void 0, n), function(a2) {
      var f = t.__N ? t.__N[0] : t.__[0], s = t.t(f, a2);
      f !== s && (t.__N = [s, t.__[1]], t.__c.setState({}));
    }], t.__c = o, !o.u)) {
      var i = function(a2, f, s) {
        if (!t.__c.__H) return true;
        var m2 = t.__c.__H.__.filter(function(e) {
          return e.__c;
        });
        if (m2.every(function(e) {
          return !e.__N;
        })) return !h2 || h2.call(this, a2, f, s);
        var V = false;
        return m2.forEach(function(e) {
          if (e.__N) {
            var P3 = e.__[0];
            e.__ = e.__N, e.__N = void 0, P3 !== e.__[0] && (V = true);
          }
        }), !(!V && t.__c.props === a2) && (!h2 || h2.call(this, a2, f, s));
      };
      o.u = true;
      var h2 = o.shouldComponentUpdate, N2 = o.componentWillUpdate;
      o.componentWillUpdate = function(a2, f, s) {
        if (this.__e) {
          var m2 = h2;
          h2 = void 0, i(a2, f, s), h2 = m2;
        }
        N2 && N2.call(this, a2, f, s);
      }, o.shouldComponentUpdate = i;
    }
    return t.__N || t.__;
  }
  function R2() {
    for (var _2; _2 = x.shift(); ) if (_2.__P && _2.__H) try {
      _2.__H.__h.forEach(d), _2.__H.__h.forEach(E2), _2.__H.__h = [];
    } catch (n) {
      _2.__H.__h = [], a.__e(n, _2.__v);
    }
  }
  a.__b = function(_2) {
    o = null, g && g(_2);
  }, a.__r = function(_2) {
    A2 && A2(_2), c = 0;
    var n = (o = _2.__c).__H;
    n && (H2 === o ? (n.__h = [], o.__h = [], n.__.forEach(function(u) {
      u.__N && (u.__ = u.__N), u.__V = p, u.__N = u.i = void 0;
    })) : (n.__h.forEach(d), n.__h.forEach(E2), n.__h = [], c = 0)), H2 = o;
  }, a.diffed = function(_2) {
    C2 && C2(_2);
    var n = _2.__c;
    n && n.__H && (n.__H.__h.length && (x.push(n) !== 1 && b2 === a.requestAnimationFrame || ((b2 = a.requestAnimationFrame) || S2)(R2)), n.__H.__.forEach(function(u) {
      u.i && (u.__H = u.i), u.__V !== p && (u.__ = u.__V), u.i = void 0, u.__V = p;
    })), H2 = o = null;
  }, a.__c = function(_2, n) {
    n.some(function(u) {
      try {
        u.__h.forEach(d), u.__h = u.__h.filter(function(t) {
          return !t.__ || E2(t);
        });
      } catch (t) {
        n.some(function(i) {
          i.__h && (i.__h = []);
        }), n = [], a.__e(t, u.__v);
      }
    }), F2 && F2(_2, n);
  }, a.unmount = function(_2) {
    q2 && q2(_2);
    var n, u = _2.__c;
    u && u.__H && (u.__H.__.forEach(function(t) {
      try {
        d(t);
      } catch (i) {
        n = i;
      }
    }), u.__H = void 0, n && a.__e(n, u.__v));
  };
  var D2 = typeof requestAnimationFrame == "function";
  function S2(_2) {
    var n, u = function() {
      clearTimeout(t), D2 && cancelAnimationFrame(n), setTimeout(_2);
    }, t = setTimeout(u, 100);
    D2 && (n = requestAnimationFrame(u));
  }
  function d(_2) {
    var n = o, u = _2.__c;
    typeof u == "function" && (_2.__c = void 0, u()), o = n;
  }
  function E2(_2) {
    var n = o;
    _2.__c = _2.__(), o = n;
  }
  function U(_2, n) {
    return typeof n == "function" ? n(_2) : n;
  }

  // https://esm.sh/preact@10.19.3/denonext/jsx-runtime.mjs
  var d2 = 0;
  var x2 = Array.isArray;
  function g2(t, r, e, a2, o2, i) {
    var s, n, f = {};
    for (n in r) n == "ref" ? s = r[n] : f[n] = r[n];
    var u = { type: t, props: f, key: e, ref: s, __k: null, __: null, __b: 0, __e: null, __d: void 0, __c: null, constructor: void 0, __v: --d2, __i: -1, __u: 0, __source: o2, __self: i };
    if (typeof t == "function" && (s = t.defaultProps)) for (n in s) f[n] === void 0 && (f[n] = s[n]);
    return a.vnode && a.vnode(u), u;
  }

  // app/islands/Counter.jsx
  function Counter({ initialCount = 0 }) {
    const [count, setCount] = k(initialCount);
    return /* @__PURE__ */ g2("div", { style: { border: "1px solid #ccc", padding: "10px", borderRadius: "5px" }, children: [
      /* @__PURE__ */ g2("p", { children: [
        "Count: ",
        count
      ] }),
      /* @__PURE__ */ g2("button", { onClick: () => setCount(count + 1), children: "Increment" })
    ] });
  }

  // https://esm.sh/preact-render-to-string@6.3.1/X-ZHByZWFjdEAxMC4xOS4z/denonext/preact-render-to-string.mjs
  var q3 = /[\s\n\\/='"\0<>]/;
  var z2 = /^(xlink|xmlns|xml)([A-Z])/;
  var W2 = /^accessK|^auto[A-Z]|^ch|^col|cont|cross|dateT|encT|form[A-Z]|frame|hrefL|inputM|maxL|minL|noV|playsI|readO|rowS|spellC|src[A-Z]|tabI|item[A-Z]/;
  var G2 = /^ac|^ali|arabic|basel|cap|clipPath$|clipRule$|color|dominant|enable|fill|flood|font|glyph[^R]|horiz|image|letter|lighting|marker[^WUH]|overline|panose|pointe|paint|rendering|shape|stop|strikethrough|stroke|text[^L]|transform|underline|unicode|units|^v[^i]|^w|^xH/;
  var J2 = /["&<]/;
  function S3(e) {
    if (e.length === 0 || J2.test(e) === false) return e;
    for (var r = 0, t = 0, o2 = "", l2 = ""; t < e.length; t++) {
      switch (e.charCodeAt(t)) {
        case 34:
          l2 = "&quot;";
          break;
        case 38:
          l2 = "&amp;";
          break;
        case 60:
          l2 = "&lt;";
          break;
        default:
          continue;
      }
      t !== r && (o2 += e.slice(r, t)), o2 += l2, r = t + 1;
    }
    return t !== r && (o2 += e.slice(r, t)), o2;
  }
  var B3 = {};
  var Q2 = /* @__PURE__ */ new Set(["animation-iteration-count", "border-image-outset", "border-image-slice", "border-image-width", "box-flex", "box-flex-group", "box-ordinal-group", "column-count", "fill-opacity", "flex", "flex-grow", "flex-negative", "flex-order", "flex-positive", "flex-shrink", "flood-opacity", "font-weight", "grid-column", "grid-row", "line-clamp", "line-height", "opacity", "order", "orphans", "stop-opacity", "stroke-dasharray", "stroke-dashoffset", "stroke-miterlimit", "stroke-opacity", "stroke-width", "tab-size", "widows", "z-index", "zoom"]);
  var X2 = /[A-Z]/g;
  function Y2(e) {
    var r = "";
    for (var t in e) {
      var o2 = e[t];
      if (o2 != null && o2 !== "") {
        var l2 = t[0] == "-" ? t : B3[t] || (B3[t] = t.replace(X2, "-$&").toLowerCase()), y = ";";
        typeof o2 != "number" || l2.startsWith("--") || Q2.has(l2) || (y = "px;"), r = r + l2 + ":" + o2 + y;
      }
    }
    return r || void 0;
  }
  var E3;
  var _;
  var k2;
  var h;
  var F3 = [];
  var M2 = Array.isArray;
  var Z2 = Object.assign;
  function j2(e, r) {
    var t = a.__s;
    a.__s = true, E3 = a.__b, _ = a.diffed, k2 = a.__r, h = a.unmount;
    var o2 = re(H, null);
    o2.__k = [e];
    try {
      return m(e, r || R3, false, void 0, o2);
    } finally {
      a.__c && a.__c(e, F3), a.__s = t, F3.length = 0;
    }
  }
  function O2() {
    this.__d = true;
  }
  var R3 = {};
  function P2(e, r) {
    var t, o2 = e.type, l2 = true;
    return e.__c ? (l2 = false, (t = e.__c).state = t.__s) : t = new o2(e.props, r), e.__c = t, t.__v = e, t.props = e.props, t.context = r, t.__d = true, t.state == null && (t.state = R3), t.__s == null && (t.__s = t.state), o2.getDerivedStateFromProps ? t.state = Z2({}, t.state, o2.getDerivedStateFromProps(t.props, t.state)) : l2 && t.componentWillMount ? (t.componentWillMount(), t.state = t.__s !== t.state ? t.__s : t.state) : !l2 && t.componentWillUpdate && t.componentWillUpdate(), k2 && k2(e), t.render(t.props, t.state, r);
  }
  function m(e, r, t, o2, l2) {
    if (e == null || e === true || e === false || e === "") return "";
    if (typeof e != "object") return typeof e == "function" ? "" : S3(e + "");
    if (M2(e)) {
      var y = "";
      l2.__k = e;
      for (var A3 = 0; A3 < e.length; A3++) {
        var L = e[A3];
        L != null && typeof L != "boolean" && (y += m(L, r, t, o2, l2));
      }
      return y;
    }
    if (e.constructor !== void 0) return "";
    e.__ = l2, E3 && E3(e);
    var T, n, p2, i = e.type, c2 = e.props, w = r;
    if (typeof i == "function") {
      if (i === H) {
        if (c2.tpl) {
          for (var C3 = "", x3 = 0; x3 < c2.tpl.length; x3++) if (C3 += c2.tpl[x3], c2.exprs && x3 < c2.exprs.length) {
            var v2 = c2.exprs[x3];
            if (v2 == null) continue;
            typeof v2 != "object" || v2.constructor !== void 0 && !M2(v2) ? C3 += v2 : C3 += m(v2, r, t, o2, e);
          }
          return C3;
        }
        if (c2.UNSTABLE_comment) return "<!--" + S3(c2.UNSTABLE_comment || "") + "-->";
        n = c2.children;
      } else {
        if ((T = i.contextType) != null) {
          var H3 = r[T.__c];
          w = H3 ? H3.props.value : T.__;
        }
        if (i.prototype && typeof i.prototype.render == "function") n = P2(e, w), p2 = e.__c;
        else {
          e.__c = p2 = { __v: e, props: c2, context: w, setState: O2, forceUpdate: O2, __d: true, __h: [] };
          for (var U2 = 0; p2.__d && U2++ < 25; ) p2.__d = false, k2 && k2(e), n = i.call(p2, c2, w);
          p2.__d = true;
        }
        if (p2.getChildContext != null && (r = Z2({}, r, p2.getChildContext())), (i.getDerivedStateFromError || p2.componentDidCatch) && a.errorBoundaries) {
          var D3 = "";
          n = n != null && n.type === H && n.key == null ? n.props.children : n;
          try {
            return D3 = m(n, r, t, o2, e);
          } catch ($2) {
            return i.getDerivedStateFromError && (p2.__s = i.getDerivedStateFromError($2)), p2.componentDidCatch && p2.componentDidCatch($2, {}), p2.__d && (n = P2(e, r), (p2 = e.__c).getChildContext != null && (r = Z2({}, r, p2.getChildContext())), D3 = m(n = n != null && n.type === H && n.key == null ? n.props.children : n, r, t, o2, e)), D3;
          } finally {
            _ && _(e), e.__ = void 0, h && h(e);
          }
        }
      }
      var V = m(n = n != null && n.type === H && n.key == null ? n.props.children : n, r, t, o2, e);
      return _ && _(e), e.__ = void 0, h && h(e), V;
    }
    var f, d3 = "<" + i, g3 = "";
    for (var a2 in c2) {
      var s = c2[a2];
      switch (a2) {
        case "children":
          f = s;
          continue;
        case "key":
        case "ref":
        case "__self":
        case "__source":
          continue;
        case "htmlFor":
          if ("for" in c2) continue;
          a2 = "for";
          break;
        case "className":
          if ("class" in c2) continue;
          a2 = "class";
          break;
        case "defaultChecked":
          a2 = "checked";
          break;
        case "defaultSelected":
          a2 = "selected";
          break;
        case "defaultValue":
        case "value":
          switch (a2 = "value", i) {
            case "textarea":
              f = s;
              continue;
            case "select":
              o2 = s;
              continue;
            case "option":
              o2 != s || "selected" in c2 || (d3 += " selected");
          }
          break;
        case "dangerouslySetInnerHTML":
          g3 = s && s.__html;
          continue;
        case "style":
          typeof s == "object" && (s = Y2(s));
          break;
        case "acceptCharset":
          a2 = "accept-charset";
          break;
        case "httpEquiv":
          a2 = "http-equiv";
          break;
        default:
          if (z2.test(a2)) a2 = a2.replace(z2, "$1:$2").toLowerCase();
          else {
            if (q3.test(a2)) continue;
            a2[4] !== "-" && a2 !== "draggable" || s == null ? t ? G2.test(a2) && (a2 = a2 === "panose1" ? "panose-1" : a2.replace(/([A-Z])/g, "-$1").toLowerCase()) : W2.test(a2) && (a2 = a2.toLowerCase()) : s += "";
          }
      }
      s != null && s !== false && typeof s != "function" && (d3 = s === true || s === "" ? d3 + " " + a2 : d3 + " " + a2 + '="' + S3(s + "") + '"');
    }
    if (q3.test(i)) throw new Error(i + " is not a valid HTML tag name in " + d3 + ">");
    return g3 || (typeof f == "string" ? g3 = S3(f) : f != null && f !== false && f !== true && (g3 = m(f, r, i === "svg" || i !== "foreignObject" && t, o2, e))), _ && _(e), e.__ = void 0, h && h(e), !g3 && N.has(i) ? d3 + "/>" : d3 + ">" + g3 + "</" + i + ">";
  }
  var N = /* @__PURE__ */ new Set(["area", "base", "br", "col", "command", "embed", "hr", "img", "input", "keygen", "link", "meta", "param", "source", "track", "wbr"]);
  var re2 = j2;

  // app/islands/_ssr_entry.js
  var components = {
    "Counter": Counter
  };
  globalThis.SalviaSSR = {
    render: function(name, props) {
      const Component = components[name];
      if (!Component) {
        throw new Error("Component not found: " + name);
      }
      const vnode = re(Component, props);
      return re2(vnode);
    }
  };
})();
