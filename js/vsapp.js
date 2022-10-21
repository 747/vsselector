
/*
 * == Modal (instructions) control ==
 */
/*
 * run!
 */
/*
 * == VDOM models ==
 */
var BigBox, CharList, CharTab, CharTag, External, Header, I, PickChar, Picker, Row, Search, SearchBox, Social, TheApp, Toggler, VResult, Workspace, elAbout, hint, isObject, messages, numlike, onMatch, pickerTab, popup, query, signboard, uiLang,
  indexOf = [].indexOf;

Number.prototype.toUcs2 = function() {
  var down, hs, ls;
  if ((0 <= this && this <= 0xFFFD)) {
    return String.fromCharCode(this);
  } else if ((0xFFFF < this && this <= 0x10FFFD)) {
    down = this - 0x10000;
    hs = 0xD800 + (down >> 0xA);
    ls = 0xDC00 + (down & 0x3FF);
    return `${String.fromCharCode(hs)}${String.fromCharCode(ls)}`;
  } else {
    return '\uFFFD';
  }
};

Number.prototype.toLowerU = function() {
  return sprintf("%04x", this);
};

Number.prototype.toUpperU = function() {
  return sprintf("%04X", this);
};

Number.prototype.formatU = function() {
  return `U+${this.toUpperU()}`;
};

Number.prototype.isFunctionalCodePoint = function() {
  return (0xFE00 <= this && this <= 0xFE0F) || (0xE0100 <= this && this <= 0xE01EF) || (0x180B <= this && this <= 0x180D) || (0x1F3FB <= this && this <= 0x1F3FF) || [0x200D, 0xE007F].indexOf(+this) >= 0;
};

Number.prototype.isWhitespaceCodePoint = function() {
  return (0x0009 <= this && this <= 0x000D) || (0x2000 <= this && this <= 0x200A) || (0x2028 <= this && this <= 0x2029) || [0x0020, 0x0085, 0x00A0, 0x1680, 0x202F, 0x205F, 0x3000].indexOf(+this) >= 0;
};

String.prototype.getFirstCodePoint = function() {
  if (/^[\uD800-\uDBFF][\uDC00-\uDFFF]/.test(this)) {
    return 0x10000 + (this.charCodeAt(0) - 0xD800 << 0xA) + this.charCodeAt(1) - 0xDC00;
  } else if (/^[\u0000-\uD799\uE000-\uFFFD]/.test(this)) {
    return this.charCodeAt(0);
  } else {
    return void 0;
  }
};

String.prototype.searchCodePoint = function() {
  var i, j, len1, matched, n, norm, results1, s, segs;
  segs = this.match(/(?:U[-+])*[0-9A-F]{4,8}|[\uD800-\uDBFF][\uDC00-\uDFFF]|(?!\s)[\u0000-\uD799\uE000-\uFFFD]/gi);
  norm = (function() {
    var j, len1, results1;
    results1 = [];
    for (j = 0, len1 = segs.length; j < len1; j++) {
      s = segs[j];
      if (matched = /^\s*(?:U[-+])*([0-9A-F]{4,8})/i.exec(s)) {
        results1.push(parseInt(matched[1], 16));
      } else {
        results1.push(s.getFirstCodePoint());
      }
    }
    return results1;
  })();
  results1 = [];
  for (i = j = 0, len1 = norm.length; j < len1; i = ++j) {
    n = norm[i];
    if ((n != null) && !n.isFunctionalCodePoint() && !n.isWhitespaceCodePoint() && norm.indexOf(n) === i) {
      results1.push(n);
    }
  }
  return results1;
};

String.prototype.toCodepoints = function() {
  var first, range;
  if (this.length <= 0) {
    return [];
  } else {
    first = this.getFirstCodePoint();
    range = first && first > 0xFFFF ? 2 : 1;
    return [first].concat(this.substr(range).toCodepoints());
  }
};

String.prototype.encodeAsParam = function() {
  return this.toCodepoints().eachToHex().join('-');
};

String.prototype.decodeAsParam = function() {
  var e;
  return ((function() {
    var j, len1, ref, results1;
    ref = this.split('-');
    results1 = [];
    for (j = 0, len1 = ref.length; j < len1; j++) {
      e = ref[j];
      results1.push(parseInt(e, 16).toUcs2());
    }
    return results1;
  }).call(this)).join('');
};

Array.prototype.eachToUcs2 = function() {
  var e, j, len1, ref, results1;
  ref = this;
  results1 = [];
  for (j = 0, len1 = ref.length; j < len1; j++) {
    e = ref[j];
    results1.push(e.toUcs2());
  }
  return results1;
};

Array.prototype.eachToHex = function() {
  var e, j, len1, ref, results1;
  ref = this;
  results1 = [];
  for (j = 0, len1 = ref.length; j < len1; j++) {
    e = ref[j];
    results1.push(e.toString(16));
  }
  return results1;
};

Array.prototype.eachToUpperU = function() {
  var e, j, len1, ref, results1;
  ref = this;
  results1 = [];
  for (j = 0, len1 = ref.length; j < len1; j++) {
    e = ref[j];
    results1.push(e.toUpperU());
  }
  return results1;
};

Array.prototype.eachToLowerU = function() {
  var e, j, len1, ref, results1;
  ref = this;
  results1 = [];
  for (j = 0, len1 = ref.length; j < len1; j++) {
    e = ref[j];
    results1.push(e.toLowerU());
  }
  return results1;
};

numlike = function(x) {
  return +x === +x;
};

isObject = function(value) {
  return value && typeof value === 'object' && value.constructor === Object;
};

elAbout = document.getElementById('about');

popup = function() {
  return elAbout.className += ' is-active';
};

document.getElementById('unmodal').onclick = function() {
  return elAbout.className = elAbout.className.replace(/(?:^|\s)is-active(?![-\w])/g, '');
};

uiLang = {
  value: "ja",
  reset: true,
  set: function(v) {
    var old;
    old = uiLang.value;
    uiLang.value = v ? v : 'ja';
    return uiLang.reset = uiLang.value === old ? false : true;
  }
};

signboard = {
  value: "",
  set: function(v) {
    return signboard.value = v;
  },
  del: function(p, w) {
    var s;
    if (numlike(p) && numlike(w)) {
      s = signboard.value;
      signboard.value = s.slice(0, +p) + s.slice(+p + +w);
    }
    return false;
  },
  ins: function(v) {
    var area, e, o, s;
    area = document.getElementById('bigbox');
    [s, o, e] = [signboard.value, area.selectionStart, area.selectionEnd];
    return signboard.value = s.slice(0, o) + v + s.slice(e);
  }
};

pickerTab = {
  source: "ivs",
  set: function(v) {
    return pickerTab.source = v;
  }
};

query = {
  box: "",
  boxed: "",
  word: [],
  phase: "",
  results: [],
  error: "",
  filters: [],
  tab: void 0,
  visSeq: [],
  allowed: function(name) {
    return indexOf.call(query.filters, name) < 0;
  },
  filter: function(name) {
    var index;
    index = query.filters.indexOf(name);
    if (index < 0) {
      return query.filters.push(name);
    } else {
      return query.filters.splice(index, 1);
    }
  },
  show: function(idx) {
    return query.tab = idx;
  },
  visible: function(group) {
    return indexOf.call(query.visSeq, group) >= 0;
  },
  toggleSeq: function(group) {
    var index;
    index = query.visSeq.indexOf(group);
    if (index < 0) {
      return query.visSeq.push(group);
    } else {
      return query.visSeq.splice(index, 1);
    }
  },
  input: function(text) {
    return query.box = text;
  },
  fetch: function() {
    var c, ch, chunks, cp, e, hexes, keys;
    cp = query.box.toString().searchCodePoint();
    if (cp != null) {
      query.phase = "wait";
      query.word = cp;
      query.results = [];
      query.tab = void 0;
      query.visSeq = [];
      hexes = (function() {
        var j, len1, results1;
        results1 = [];
        for (j = 0, len1 = cp.length; j < len1; j++) {
          c = cp[j];
          results1.push(c.toUpperU());
        }
        return results1;
      })();
      chunks = (function() {
        var j, len1, results1;
        results1 = [];
        for (j = 0, len1 = hexes.length; j < len1; j++) {
          e = hexes[j];
          results1.push(e.slice(0, e.length - 2));
        }
        return results1;
      })();
      keys = (function() {
        var j, len1, results1;
        results1 = [];
        for (j = 0, len1 = hexes.length; j < len1; j++) {
          e = hexes[j];
          results1.push(e.slice(-2));
        }
        return results1;
      })();
      return Promise.all((function() {
        var j, len1, results1;
        results1 = [];
        for (j = 0, len1 = chunks.length; j < len1; j++) {
          ch = chunks[j];
          results1.push(query.request(ch));
        }
        return results1;
      })()).then(function(results) {
        var i, j, len1, r, res;
        for (i = j = 0, len1 = results.length; j < len1; i = ++j) {
          res = results[i];
          r = res[keys[i]];
          query.results[i] = r != null ? query.build(r, cp[i]) : void 0;
        }
        query.phase = "got";
        return query.tab = 0;
      }).catch(function(error) {
        query.phase = "error";
        return query.error = error.message;
      });
    }
  },
  request: function(block) {
    return m.request({
      type: "get",
      url: `./chars/${block}.json`
    });
  },
  build: function(r, cp) {
    var basechar, cat, cname, coll, id, j, len1, name, o, seq, type, v, vars;
    [o, id, type, name, vars, coll, seq] = [[], "i", "t", "n", r["V"], "c", "S"];
    cat = TYPES[r[type]];
    basechar = TYPES[r[type]] === 'compat' ? vars[0][id] : cp;
    o.push({
      'id': cp,
      'type': cat || r[type],
      'name': r[name],
      'cid': "base"
    });
    if (r[seq]) {
      o.push(query.buildSeq(r[seq], [cp]));
    }
    for (j = 0, len1 = vars.length; j < len1; j++) {
      v = vars[j];
      cname = COLLS[v[coll]];
      o.push({
        'id': v[id],
        'type': TYPES[v[type]] || v[type],
        'name': v[name],
        'cid': cname,
        'coll': v[coll],
        'base': cname !== 'parent' ? basechar : void 0
      });
      if (v[seq]) {
        o.push(query.buildSeq(v[seq], [cp, v[id]]));
      }
    }
    return o;
  },
  buildSeq: function(seqs, bases) {
    var genid, j, len1, results1, s;
    genid = bases.join('-');
    results1 = [];
    for (j = 0, len1 = seqs.length; j < len1; j++) {
      s = seqs[j];
      results1.push({
        'seq': bases.concat(s['q']),
        'name': s['n'],
        'klass': genid
      });
    }
    return results1;
  }
};

hint = {
  loaded: false,
  data: [],
  searcher: void 0,
  max: 20,
  suggest: function(text) {
    return this.searcher.search(text).slice(0, this.max);
  },
  load: function() {
    var langs, ln;
    langs = ['en'];
    if (uiLang.value !== 'en-us') {
      langs.push(uiLang.value);
    }
    hint.loaded = false;
    return Promise.all((function() {
      var j, len1, results1;
      results1 = [];
      for (j = 0, len1 = langs.length; j < len1; j++) {
        ln = langs[j];
        results1.push(hint.request(ln));
      }
      return results1;
    })()).then(function(results) {
      var entry, j, len1, len2, q, r, rd, ref, refs, res;
      for (j = 0, len1 = results.length; j < len1; j++) {
        res = results[j];
        rd = res['D'];
        ref = res['L'];
        for (entry in ref) {
          refs = ref[entry];
          for (q = 0, len2 = refs.length; q < len2; q++) {
            r = refs[q];
            hint.data.push({
              label: entry,
              value: rd[r][0],
              desc: rd[r][1]
            });
          }
        }
      }
      hint.searcher = new Fuse(hint.data, {
        includeMatches: true,
        threshold: 0.4,
        keys: ['label']
      });
      if (hint.searcher) {
        return hint.loaded = true;
      }
    });
  },
  request: function(lang) {
    return m.request({
      type: "get",
      url: `./utils/${lang}.json`
    });
  }
};

messages = {
  langname: {
    'ja': '日本語',
    'en-us': 'English',
    'zh-hans': '简体中文',
    'zh-hant': '繁體中文'
  },
  lang: {
    'ja': '言語',
    'en-us': 'Language',
    'zh-hans': '语言',
    'zh-hant': '語言'
  },
  title: {
    'ja': '異体字セレクタセレクタ',
    'en-us': 'Variation Selector Selector',
    'zh-hans': '选异选',
    'zh-hant': '選異選'
  },
  help: {
    'ja': '説明',
    'en-us': 'Help',
    'zh-hans': '简易指南',
    'zh-hant': '簡易指南'
  },
  github: {
    'ja': 'GitHub',
    'en-us': 'GitHub',
    'zh-hans': 'GitHub',
    'zh-hant': 'GitHub'
  },
  tab_ivs: {
    'ja': 'IVS',
    'en-us': 'IVS',
    'zh-hans': 'IVS',
    'zh-hant': 'IVS'
  },
  tab_vs: {
    'ja': '(F)VS',
    'en-us': '(F)VS',
    'zh-hans': '(F)VS',
    'zh-hant': '(F)VS'
  },
  tab_emoji: {
    'ja': '絵文字',
    'en-us': 'Emoji',
    'zh-hans': 'Emoji',
    'zh-hant': '表情圖示'
  },
  tab_utils: {
    'ja': '補助',
    'en-us': 'Utils',
    'zh-hans': '辅助',
    'zh-hant': '輔助'
  },
  paste_left: {
    'ja': '⬅クリックで挿入',
    'en-us': 'Click to paste to left',
    'zh-hans': '点字放进左栏',
    'zh-hant': '點字放進左欄'
  },
  paste_up: {
    'ja': '⬆クリックで挿入',
    'en-us': 'Click to paste up',
    'zh-hans': '点字放进上栏',
    'zh-hant': '點字放進上欄'
  },
  share: {
    'ja': '内容をシェア',
    'en-us': 'Share to:',
    'zh-hans': '分享到',
    'zh-hant': '分享到'
  },
  share_tag: {
    'ja': '異体字セレクタセレクタ',
    'en-us': 'vsselector',
    'zh-hans': '选异选',
    'zh-hant': '選異選'
  },
  external: {
    'ja': '%(site)s で「%(char)s」を表示',
    'en-us': 'Lookup ‹%(char)s› on %(site)s',
    'zh-hans': '%(site)s 上查看“%(char)s”字',
    'zh-hant': '%(site)s 上查看「%(char)s」字'
  },
  insert: {
    'ja': '⬆挿入',
    'en-us': 'Insert ⬆',
    'zh-hans': '⬆粘贴',
    'zh-hant': '⬆貼上'
  },
  copy: {
    'ja': 'コピー',
    'en-us': 'Copy',
    'zh-hans': '复制',
    'zh-hant': '複製'
  },
  open_seq: {
    'ja': 'この字から始まるシークエンス',
    'en-us': 'Sequences starting with this variant',
    'zh-hans': '展开以此字开头的序列',
    'zh-hant': '展開以此字開頭的序列'
  },
  close_seq: {
    'ja': 'このシークエンスを閉じる',
    'en-us': 'Hide sequences',
    'zh-hans': '关闭序列列表',
    'zh-hant': '關閉序列列表'
  },
  col_actual: {
    'ja': '表示',
    'en-us': 'Output',
    'zh-hans': '字符',
    'zh-hant': '字符'
  },
  col_code: {
    'ja': 'コード',
    'en-us': 'Code Point',
    'zh-hans': '主字码位',
    'zh-hant': '主字碼位'
  },
  col_var: {
    'ja': 'セレクタ',
    'en-us': 'Selector',
    'zh-hans': '选择符',
    'zh-hant': '選擇符'
  },
  col_image: {
    'ja': '画像',
    'en-us': 'Image',
    'zh-hans': '字样',
    'zh-hant': '字樣'
  },
  col_collection: {
    'ja': 'コレクション',
    'en-us': 'Collection',
    'zh-hans': '集合',
    'zh-hant': '集合'
  },
  col_source: {
    'ja': '識別名',
    'en-us': 'Identifier',
    'zh-hans': '标识名称',
    'zh-hant': '識別名稱'
  },
  not_found: {
    'ja': '見つかりませんでした',
    'en-us': 'Not found.',
    'zh-hans': '无查询结果可显示',
    'zh-hant': '無查詢結果可顯示'
  },
  search_init: {
    'ja': '以下に検索結果が表示されます',
    'en-us': 'Your search results will show up here.',
    'zh-hans': '这里显示查询结果',
    'zh-hant': '此處顯示查詢結果'
  },
  example: {
    'ja': '例　1F468:ハート:葛飾',
    'en-us': 'ex. 1F468:heart:葛飾',
    'zh-hans': '例　1F468:heart:葛飾',
    'zh-hant': '例　1F468:heart:葛飾'
  },
  search_button: {
    'ja': '登録済の異体字を検索',
    'en-us': 'Search available variants',
    'zh-hans': '查询已编码的变体',
    'zh-hant': '查詢已編碼的變體'
  },
  collections: {
    'ja': 'コレクションを表示 (IVS)',
    'en-us': 'Toggle by collection (IVS)',
    'zh-hans': '按 IVS 集合筛选',
    'zh-hant': '依 IVS 集合篩選'
  },
  coll_base: {
    'ja': '基底文字',
    'en-us': 'Base',
    'zh-hans': '基本字符',
    'zh-hant': '基本字符'
  },
  coll_parent: {
    'ja': '親文字',
    'en-us': 'Parent',
    'zh-hans': '父字符',
    'zh-hant': '父字符'
  },
  coll_standardized: {
    'ja': '標準異体字',
    'en-us': 'Standardized',
    'zh-hans': '标准变体',
    'zh-hant': '標準變體'
  },
  coll_modifier: {
    'ja': '修飾文字',
    'en-us': 'Modifier',
    'zh-hans': '修饰符',
    'zh-hant': '修飾符'
  },
  coll_unknown: {
    'ja': '不明',
    'en-us': 'Unknown',
    'zh-hans': '未知',
    'zh-hant': '未知'
  }
};

I = function(key) {
  var k;
  k = key.toLowerCase();
  if (messages[k]) {
    return messages[k][uiLang.value] || messages[k]['ja'];
  } else {
    return `Message <<${k}>>?`;
  }
};

/*
 * == VDOM components ==
 */
/* Pre-defined variables
 * TYPES = (index-to-type name mapping)
 * COLLS = (index-to-collection name mapping)
 * NAMES = (valid IVD collection names)
 * MISSING = (emoji codes missing from the main glyph lib)
 */
//::: Header :::#
Header = {
  modal: function(e) {
    e.redraw = false;
    return popup();
  },
  view: function() {
    return m('.navbar.is-dark.is-fixed-top', m('.navbar-brand.is-clipped', m('p.site-title.navbar-item.is-clipped.has-background-link', m('b.is-clipped', I('title')), "\u00A0(β)")), m('.navbar-menu', m('.navbar-start'), m('.navbar-end', m('.navbar-item.has-dropdown.is-hoverable', m('a.navbar-link', m('img.icon.is-large[src="images/translate-2.svg"]', {
      title: I('lang', {
        alt: I('lang')
      })
    })), m('.navbar-dropdown', (function() {
      var l, ref, results1, t;
      ref = messages['langname'];
      results1 = [];
      for (t in ref) {
        l = ref[t];
        if (t !== uiLang.value) {
          results1.push(m(`a.navbar-item[href=/${t}/${query.box.encodeAsParam()}]`, {
            oncreate: m.route.link
          }, l));
        }
      }
      return results1;
    })())), m('a.navbar-item.modality', {
      onclick: Header.modal
    }, I('help')), m('a.navbar-item', {
      href: "https://github.com/747/vsselector",
      target: "_blank"
    }, m('img.icon.is-large[src="images/github.svg"]', {
      title: I('github', {
        alt: I('github')
      })
    })))));
  }
};

//::: Picker Area (top) :::#
CharTag = {
  f: function(e) {
    var d;
    d = e.target.parentElement.dataset;
    return signboard.del(d.pos, d.width);
  },
  view: function(v) {
    var c, color;
    c = +v.attrs.code;
    color = c.isFunctionalCodePoint() ? 'is-success' : 'is-info';
    return m('span.tag', {
      class: color,
      'data-pos': v.attrs.pos,
      'data-width': v.attrs.width
    }, c.toUpperU(), m('button.delete.is-small.delete-char', {
      onclick: CharTag.f
    }));
  }
};

CharList = {
  view: function(v) {
    var c;
    c = signboard.value.toCodepoints();
    return m('p#breakdown-body.message-body.tags', (function() {
      var code, j, len1, leng, offset, results1, sum;
      sum = 0;
      results1 = [];
      for (j = 0, len1 = c.length; j < len1; j++) {
        code = c[j];
        offset = sum;
        leng = code.toUcs2().length;
        sum += leng;
        results1.push(m(CharTag, {
          pos: offset,
          width: leng,
          code: code
        }));
      }
      return results1;
    })());
  }
};

BigBox = {
  f: function() {
    return m.withAttr('value', signboard.set);
  },
  view: function() {
    return m('textarea#bigbox.textarea.is-fullwidth', {
      placeholder: `${0x1F4DD.toUcs2()}...`,
      value: signboard.value,
      onchange: BigBox.f(),
      onkeyup: BigBox.f(),
      onpaste: BigBox.f()
    });
  }
};

PickChar = {
  view: function(v) {
    var a;
    a = v.attrs;
    return m('li', {
      id: a.id
    }, m('a.pick', {
      'data-char': a.data.toUcs2(),
      onclick: m.withAttr('data-char', signboard.ins)
    }, m('img.glyph', {
      title: a.title,
      alt: a.alt,
      src: a.src
    })));
  }
};

Toggler = {
  f: function(e) {
    return pickerTab.set(e.target.parentElement.dataset.tab);
  },
  view: function() {
    var props;
    props = {
      onclick: Toggler.f
    };
    return m('#groups.tabs.is-centered.is-toggle', m('ul', m('li[data-tab="ivs"]', m('a.toggler', props, I('tab_ivs'))), m('li[data-tab="vs"]', m('a.toggler', props, I('tab_vs'))), m('li[data-tab="emod"]', m('a.toggler', props, I('tab_emoji'))), m('li[data-tab="util"]', m('a.toggler', props, I('tab_utils')))));
  }
};

Picker = {
  view: function() {
    return m('#picker.column.is-5.message.is-success', m('p.message-header', m('span.is-inline-tablet.is-hidden-mobile', I('paste_left')), m('span.touch-picker-leader.is-hidden-tablet.is-inline-mobile.has-text-centered', I('paste_up'))), m('#catalog.message-body', (function() {
      switch (pickerTab.source) {
        case "ivs":
          return m('ul#ivs', (function() {
            var ivs, j, n, results1;
            ivs = function(x) {
              return 0xE0100 + x - 17;
            };
            results1 = [];
            for (n = j = 17; j <= 256; n = ++j) {
              results1.push(m(PickChar, {
                id: `ivs-${n}`,
                data: ivs(n),
                title: `VS${n} (${ivs(n).formatU()})`,
                alt: `VS${n}`,
                src: `./images/selectors/vs-${n}.svg`
              }));
            }
            return results1;
          })());
        case "vs":
          return m('ul#vs', (function() {
            var j, n, note, results1, svs;
            svs = function(x) {
              return 0xFE00 + x - 1;
            };
            note = function(x) {
              return svs(x).formatU() + (x === 15 ? "; text style" : n === 16 ? "; emoji style" : "");
            };
            results1 = [];
            for (n = j = 1; j <= 16; n = ++j) {
              results1.push(m(PickChar, {
                id: `vs-${n}`,
                data: svs(n),
                title: `VS${n} (${note(n)})`,
                alt: `VS${n}`,
                src: `./images/selectors/vs-${n}.svg`
              }));
            }
            return results1;
          })(), (function() {
            var fvs, j, n, results1;
            fvs = function(x) {
              return 0x180B + x - 1;
            };
            results1 = [];
            for (n = j = 1; j <= 3; n = ++j) {
              results1.push(m(PickChar, {
                id: `fvs-${n}`,
                data: fvs(n),
                title: `Mongolian FVS${n} (${fvs(n).formatU()})`,
                alt: `FVS${n}`,
                src: `./images/selectors/fvs-${n}.svg`
              }));
            }
            return results1;
          })());
        case "emod":
          return m('ul#emod', (function() {
            var j, n, results1, ris;
            ris = function(x) {
              return 0x1F1E6 + x;
            };
            results1 = [];
            for (n = j = 0; j <= 25; n = ++j) {
              results1.push(m(PickChar, {
                id: `region-${n}`,
                data: ris(n),
                title: `Regional letter ${(n + 65).toUcs2()} (${ris(n).formatU()})`,
                alt: `RIS ${(n + 65).toUcs2()}`,
                src: `./images/ne/emoji_u${ris(n).toLowerU()}.svg`
              }));
            }
            return results1;
          })(), (function() {
            var emo, j, n, results1, sc;
            emo = function(x) {
              return 0x1F3FB + x - 2;
            };
            sc = function(x) {
              if (x === 2) {
                return "1-2";
              } else {
                return n;
              }
            };
            results1 = [];
            for (n = j = 2; j <= 6; n = ++j) {
              results1.push(m(PickChar, {
                id: `fitz-${n}`,
                data: emo(n),
                title: `Fitzgerald ${sc(n)} (${emo(n).formatU()})`,
                alt: `Fitz ${sc(n)}`,
                src: `./images/ne/emoji_u${emo(n).toLowerU()}.svg`
              }));
            }
            return results1;
          })(), (function() {
            var emc, j, n, results1, tx;
            emc = function(x) {
              return 0x1F9B0 + x;
            };
            tx = function(x) {
              return ['red hair', 'curly hair', 'bald', 'white hair'][x];
            };
            results1 = [];
            for (n = j = 0; j <= 3; n = ++j) {
              results1.push(m(PickChar, {
                id: `ecom-${n}`,
                data: emc(n),
                title: `Emoji component ${tx(n)} (${emc(n).formatU()})`,
                alt: tx(n).charAt(0).toUpperCase() + tx(n).slice(1),
                src: `./images/ne/emoji_u${emc(n).toLowerU()}.svg`
              }));
            }
            return results1;
          })());
        case "util":
          return m('ul#util', m(PickChar, {
            id: "zwj",
            data: 0x200D,
            title: `ZERO WIDTH JOINER (${0x200D.formatU()})`,
            alt: "ZWJ",
            src: "./images/selectors/zwj.svg"
          }), (function() {
            var j, n, results1, t, tag;
            tag = function(x) {
              return 0xE0020 + x;
            };
            t = function(x) {
              if (x === 0) {
                return ["SPACE", "SP"];
              } else if (x === 0x5F) {
                return ["END", "END"];
              } else {
                return [`\u00ab${(x + 32).toUcs2()}\u00bb`, `${(x + 32).toUcs2()}`];
              }
            };
// U+E001 is still deprecated
            results1 = [];
            for (n = j = 0; j <= 95; n = ++j) {
              results1.push(m(PickChar, {
                id: `tags-${n}`,
                data: tag(n),
                title: `Tag ${t(n)[0]} (${tag(n).formatU()})`,
                alt: `Tag ${t(n)[1]}`,
                src: `./images/selectors/tag-${n + 32}.svg`
              }));
            }
            return results1;
          })());
      }
    })(), m(Toggler)));
  }
};

Social = {
  view: function() {
    return m('.level.is-mobile', m('.level-left'), m('p#shares.content.is-small.level-right', m('span#to_share.level-item', I('share')), m('a#twitter-share.level-item', {
      onclick: function(e) {
        return Social.share(e, 'twitter');
      }
    }, m('img.glyph[alt="Twitter"]', {
      src: "images/Twitter_Social_Icon_Circle_Color.svg"
    })), m('a#line-it.level-item', {
      onclick: function(e) {
        return Social.share(e, 'line');
      }
    }, m('img.glyph[alt="LINE"]', {
      src: "images/share-d.png"
    }))));
  },
  share: function(e, t) {
    var content, message, tag, url;
    e.redraw = false;
    switch (t) {
      case 'twitter':
        url = encodeURIComponent(window.location.href);
        content = encodeURIComponent(signboard.value);
        tag = encodeURIComponent(I('share_tag'));
        return window.open(`https://twitter.com/intent/tweet?text=${content}&url=${url}&hashtags=${tag}`, "tweet", "width=550,height=480,location=yes,resizable=yes,scrollbars=yes");
      case 'line':
        message = encodeURIComponent(`${signboard.value} ${window.location.href}`);
        return window.open(`//line.me/R/msg/text/?${message}`);
    }
  }
};

Workspace = {
  view: function() {
    return m('#workspace.columns.is-multiline.section.transparent', m('.columns.is-full', m('#viewer.column.is-7', m(BigBox), m('#breakdown.message.is-warning.is-fullwidth', m(CharList)), m(Social)), m(Picker)));
  }
};

//::: Search Area (bottom) :::#
CharTab = {
  view: function(v) {
    var active, empty, link, w, x;
    w = v.attrs.codes;
    x = +v.attrs.num;
    active = function(n) {
      if (n === x) {
        return 'is-active';
      } else {
        return void 0;
      }
    };
    empty = function(n) {
      if (query.results[n] != null) {
        return void 0;
      } else {
        return 'has-background-grey-lighter';
      }
    };
    link = function(n) {
      if (n === x) {
        return void 0;
      } else {
        return m.withAttr('data-idx', query.show);
      }
    };
    return m('div#chartabs.tabs.is-boxed', m('ul', (function() {
      var ch, i, j, len1, results1;
      results1 = [];
      for (i = j = 0, len1 = w.length; j < len1; i = ++j) {
        ch = w[i];
        results1.push(m('li', {
          class: [active(i), empty(i)].join(' ')
        }, m('a', {
          'data-idx': i,
          title: ch.toUpperU(),
          onclick: link(i)
        }, ch.toUcs2())));
      }
      return results1;
    })()));
  }
};

External = {
  view: function(v) {
    var id;
    id = +v.attrs.code;
    return m('div.message.is-info', m('p.message-body', (function() {
      var i, j, len1, list, ref, s;
      list = [];
      ref = External.sites;
      for (i = j = 0, len1 = ref.length; j < len1; i = ++j) {
        s = ref[i];
        if (i > 0) {
          list.push(' ');
        }
        list.push(m('a.button.is-info', {
          href: s[1] + id[s[2]](),
          target: '_blank'
        }, sprintf(I('external'), {
          site: s[0],
          char: id.toUcs2()
        })));
      }
      return list;
    })()));
  },
  sites: [['CHISE', 'http://www.chise.org/est/view/character/', 'toUcs2'], ['GlyphWiki', 'https://glyphwiki.org/wiki/u', 'toLowerU'], ['Codepoints', 'https://codepoints.net/U+', 'toUpperU']]
};

Row = {
  view: function(v) {
    var a, base, cid, coll, id, name, seq, type;
    a = v.attrs;
    [id, base, name, type, cid, coll, seq] = [a.id, a.base, a.name, a.type, a.cid, a.coll, a.seq];
    return m('tr', {
      class: (seq ? `content message is-small is-warning collapsible ${a.klass}` : void 0)
    }, m('td', m('.field.has-addons.has-addons-centered', m('.control', m('button.button.is-dark.insert', {
      class: (seq ? 'is-small' : void 0),
      char: Row.calcChar(seq, base, id),
      onclick: m.withAttr('char', signboard.ins)
    }, I('insert'))), m('.control', m('input.autocopy.input.has-text-centered', {
      class: (function() {
        var classes, n;
        classes = seq ? ['is-small'] : [];
        classes.push((function() {
          switch (coll) {
            case "Adobe-Japan1":
              return 'ivs-aj1';
            case "Moji_Joho":
              return 'ivs-mj';
            case "Hanyo-Denshi":
            case "MSARG":
            case "KRName":
              return 'ivs-etc';
          }
        })());
        return ((function() {
          var j, len1, results1;
          results1 = [];
          for (j = 0, len1 = classes.length; j < len1; j++) {
            n = classes[j];
            if (n !== void 0) {
              results1.push(n);
            }
          }
          return results1;
        })()).join(' ');
      })(),
      value: Row.calcChar(seq, base, id)
    })), m('.control', m('button.button.clipboard.is-primary', {
      class: (seq ? 'is-small' : void 0),
      'data-clipboard-text': Row.calcChar(seq, base, id)
    }, I('copy'))))), (function() {
      var code, path, ref;
      if (seq) {
        code = seq.eachToLowerU().join('_');
        path = (0x1F1E6 <= (ref = seq[0]) && ref <= 0x1F1FF) || seq[0] === 0x1F3F4 ? `./images/te/${code.replace(/_/g, '-')}.svg` : MISSING.indexOf(code) >= 0 ? `./images/ne/supp/emoji_u${code}.svg` : `./images/ne/emoji_u${code}.svg`;
        return [
          m('td',
          {
            colSpan: 2
          },
          seq.eachToUpperU().join(' ')),
          m('td.glyph-col',
          m('img.glyph',
          {
            src: path
          })),
          m('td',
          {
            colSpan: 2
          },
          name)
        ];
      } else {
        return [
          m('td',
          `U+${base ? base.toUpperU() : id.toUpperU()}`),
          m('td',
          base ? `U+${id.toUpperU()}` : '-'),
          m('td.glyph-col',
          m('img.glyph',
          {
            src: (function() {
              switch (type) {
                case "ideograph":
                case "compat":
                  return `https://glyphwiki.org/glyph/u${base ? base.toLowerU() + '-u' : ''}${id.toLowerU()}.svg`;
                case "emoji":
                  code = `${base ? base.toLowerU() + '_' : ''}${id.toLowerU()}`;
                  return `./images/ne${MISSING.indexOf(code) >= 0 ? '/supp' : ''}/emoji_u${code}.svg`;
                default:
                  return "./images/noimage.svg";
              }
            })()
          })),
          m('td',
          (function() {
            if (cid) {
              return m('span.named',
          I(`coll_${cid}`));
            } else {
              return coll;
            }
          })()),
          m('td',
          name)
        ];
      }
    })());
  },
  header: function(id, open) {
    var txt;
    txt = open ? I('close_seq') : I('open_seq');
    return m('tr.content.message.is-small.is-warning.seq-header', {
      id: id,
      onclick: m.withAttr('id', query.toggleSeq)
    }, m('td.message-header[colspan=6]', txt));
  },
  oncreate: function() {
    return new ClipboardJS('.clipboard');
  },
  calcChar: function(seq, base, id) {
    if (seq) {
      return seq.eachToUcs2().join('');
    } else {
      return `${base ? base.toUcs2() : ''}${id.toUcs2()}`;
    }
  }
};

VResult = {
  view: function(v) {
    return m('#entries[style="overflow-x: auto"]', (function() { // until bulma officially has .table-container...
      return VResult.response(query.phase);
    })());
  },
  response: function(phase) {
    var current, fragment;
    switch (phase) {
      case 'got':
        current = query.tab;
        fragment = [
          m(CharTab,
          {
            codes: query.word,
            num: current
          }),
          m(External,
          {
            code: query.word[current]
          })
        ];
        if (query.results[current] != null) {
          fragment.push(m('table#found.table.is-fullwidth.is-marginless.transparent', m('thead', m('tr', m('th#copy', I('col_actual')), m('th#codepoint', I('col_code')), m('th#variation', I('col_var')), m('th#image', I('col_image')), m('th#collection', I('col_collection')), m('th#internal', I('col_source')))), m('tbody#charlist', (function() {
            var hid, i, j, len1, len2, q, ref, row, rows, seq;
            rows = [];
            ref = query.results[current];
            for (i = j = 0, len1 = ref.length; j < len1; i = ++j) {
              row = ref[i];
              if (query.allowed(row['coll'])) {
                if (Array.isArray(row)) {
                  hid = query.results[current][0].id + '-' + query.results[current][i - 1].id;
                  if (query.visible(hid)) {
                    rows.push((function() {
                      return Row.header(hid, true);
                    })());
                    for (q = 0, len2 = row.length; q < len2; q++) {
                      seq = row[q];
                      rows.push(m(Row, seq));
                    }
                    rows.push((function() {
                      return Row.header(hid, true);
                    })());
                  } else {
                    rows.push((function() {
                      return Row.header(hid);
                    })());
                  }
                } else if (isObject(row)) {
                  rows.push(m(Row, row));
                }
              }
            }
            return rows;
          })())));
        } else {
          fragment.push(m('#notfound.message.is-warning', m('p.has-text-centered.message-body', I('not_found'))));
        }
        return fragment;
      case 'wait':
        return m('.message.is-primary', m('p.message-body', m('button.button.is-fullwidth.is-text.is-paddingless.is-loading')));
      case 'error':
        return m('.message.is-danger', m('p.message-body', query.error));
      default:
        return m('.message.is-info', m('p.has-text-centered.message-body', I('search_init')));
    }
  }
};

SearchBox = {
  oninit: function() {
    return hint.load();
  },
  onupdate: function() {
    if (uiLang.reset) {
      uiLang.reset = false;
      return hint.load();
    }
  },
  f: function() {
    return m.withAttr('value', query.input);
  },
  key: function(e) {
    var curr, last, rebuild;
    e.redraw = false;
    if (SearchBox.suggestionsCache.length > 0) {
      last = SearchBox.suggestionsCache.length - 1;
      curr = SearchBox.selecting;
      rebuild = function() {
        SearchBox.suggestionsCache = SearchBox.buildSuggestions();
        SearchBox.keypressHappened = false;
        return m.redraw();
      };
    }
    if (e.key === 'Enter' || e.keyCode === 13 || e.which === 13) {
      if (SearchBox.keypressHappened) {
        if (curr != null) {
          return SearchBox.replaceBySuggestion(SearchBox.suggestionsCache[curr].attrs['data-char']);
        }
        SearchBox.clearSuggestions();
        query.input(e.currentTarget.value);
        Search.submit();
      }
    } else if (e.key === 'ArrowDown' || e.keyCode === 40 || e.which === 40) {
      if (last != null) {
        SearchBox.selecting = (curr == null) || curr >= last ? 0 : curr + 1;
        return rebuild();
      }
    } else if (e.key === 'ArrowUp' || e.keyCode === 38 || e.which === 38) {
      if (last != null) {
        SearchBox.selecting = (curr == null) || curr <= 0 ? last : curr - 1;
        return rebuild();
      }
    } else {
      query.input(e.currentTarget.value);
    }
    SearchBox.buffer.update();
    SearchBox.suggestBuffer.update();
    return SearchBox.keypressHappened = false;
  },
  keypressHappened: false, // keypressが発火しないkeyupは変換確定
  keypress: function(e) {
    e.redraw = false;
    return SearchBox.keypressHappened = true;
  },
  buffer: {
    clear: false,
    __timer: void 0,
    update: function() {
      clearTimeout(this.__timer);
      this.clear = false;
      return this.__timer = setTimeout((() => {
        this.clear = true;
        return m.redraw;
      }), 100);
    }
  },
  view: function() {
    return [
      m('input#searchbox.input[type=text]',
      {
        placeholder: I('example'),
        value: query.box,
        onchange: SearchBox.f(),
        onkeypress: SearchBox.keypress,
        oninput: SearchBox.key,
        onkeyup: SearchBox.key,
        onpaste: SearchBox.f()
      }),
      m('#autocomplete.panel.has-background-white',
      SearchBox.suggestionsCache)
    ];
  },
  candidate: '',
  searchCache: [],
  suggestionsCache: [],
  selecting: void 0,
  insert: function() {
    return m.withAttr('data-char', SearchBox.replaceBySuggestion);
  },
  replaceBySuggestion: function(t) {
    var after, before, str;
    str = query.box;
    before = str.indexOf(':');
    after = before + SearchBox.candidate.length + 2; // take in the closing colon, doesn't harm if nonexistent
    query.input(str.slice(0, before) + t + str.slice(after));
    return SearchBox.suggest();
  },
  clearSuggestions: function() {
    return SearchBox.suggestionsCache = [];
  },
  suggestBuffer: {
    clear: false,
    __timer: void 0,
    update: function() {
      clearTimeout(this.__timer);
      this.clear = false;
      return this.__timer = setTimeout((() => {
        this.clear = true;
        return SearchBox.suggest();
      }), 500);
    }
  },
  suggest: function() {
    var captured, end, lead, start;
    lead = query.box.indexOf(':');
    if (lead >= 0) {
      start = lead + 1;
      end = query.box.indexOf(':', start);
      captured = query.box.slice(start, (end > 0 ? end : void 0));
    } else {
      captured = '';
    }
    if (hint.loaded && captured !== SearchBox.candidate) {
      SearchBox.selecting = void 0;
      SearchBox.candidate = captured;
      SearchBox.searchCache = hint.suggest(captured);
      SearchBox.suggestionsCache = SearchBox.buildSuggestions();
    }
    return m.redraw();
  },
  buildSuggestions: function() {
    var _mk, e, emph, i, it, j, len1, marked, mi, mk, mt, ref, results1, sg;
    ref = SearchBox.searchCache;
    results1 = [];
    for (i = j = 0, len1 = ref.length; j < len1; i = ++j) {
      sg = ref[i];
      it = sg.item;
      _mk = [].concat.apply([], (function() {
        var len2, q, ref1, results2;
        ref1 = sg.matches;
        // first-level flatten
        results2 = [];
        for (q = 0, len2 = ref1.length; q < len2; q++) {
          mt = ref1[q];
          results2.push(mt.indices);
        }
        return results2;
      })());
      mk = ((function() {
        var len2, q, results2;
// uniq
        results2 = [];
        for (mi = q = 0, len2 = _mk.length; q < len2; mi = ++q) {
          e = _mk[mi];
          if (_mk.indexOf(e) === mi) {
            results2.push(e);
          }
        }
        return results2;
      })()).sort(function(a, b) {
        return a[0] - b[0];
      });
      emph = function(iv) {
        return m('mark', iv);
      };
      marked = (function() {
        var bgn, end, ep, fragment, len, len2, loss, p, q;
        fragment = it.label.toCodepoints().eachToUcs2();
        loss = 0;
        for (q = 0, len2 = mk.length; q < len2; q++) {
          ep = mk[q];
          [bgn, end] = (function() {
            var len3, results2, u;
            results2 = [];
            for (u = 0, len3 = ep.length; u < len3; u++) {
              p = ep[u];
              results2.push(p - loss);
            }
            return results2;
          })();
          len = end - bgn;
          if (len === 0) {
            fragment[bgn] = emph(fragment[bgn]);
          } else if (len > 0) {
            fragment.splice(bgn, len + 1, emph(fragment.slice(bgn, end + 1)));
            loss += len;
          }
        }
        return fragment;
      })();
      results1.push(m('a.autocomplete-item.panel-block', {
        class: SearchBox.selecting === i ? 'has-background-link has-text-white' : '',
        'data-char': it.value,
        onclick: SearchBox.insert()
      }, m('span.panel-icon.emoji-width', it.value), m('span', marked), m('span.desc.has-text-grey-light.is-size-7', it.desc)));
    }
    return results1;
  }
};

Search = {
  view: function() {
    var ivd;
    return m('#search.section', m('#query.level.is-block-touch is-block-desktop-only is-block-widescreen-only', m('.level-left', m('.level-item', m('.field.has-addons', m('p.control', m(SearchBox)), m('p.control', m('button#searchbutton.button.is-primary', {
      onclick: Search.submit
    }, m('span#searchlabel', I('search_button'))))))), m('.level-right', m('p.has-text-weight-bold.control.level-item', m('span#selectcol', I('collections'))), (function() {
      var j, len1, results1;
      results1 = [];
      for (j = 0, len1 = NAMES.length; j < len1; j++) {
        ivd = NAMES[j];
        results1.push(m('.level-item.collection-selector.control.checkbox', m('input.is-checkradio.is-block.is-success.search-filter[type=checkbox]', {
          name: ivd,
          onclick: m.withAttr('name', query.filter),
          checked: query.allowed(ivd)
        }), m('label.collection-selector-desc', {
          for: ivd,
          onclick: m.withAttr('for', query.filter) // because it shadows the checkbox
        }, ivd)));
      }
      return results1;
    })())), m(VResult));
  },
  submit: function() {
    return m.route.set(`/${uiLang.value}/${query.box.encodeAsParam()}`);
  }
};

//::: Main App :::#
TheApp = {
  view: function() {
    return [m(Header), m(Workspace), m(Search)];
  }
};

onMatch = function(a) {
  var decode;
  uiLang.set(a.lang);
  document.body.setAttribute('lang', uiLang.value);
  document.title = I('title');
  document.getElementById('about-title').textContent = (I('title')) + ' (β)';
  if (a.bbtxt) {
    signboard.set(a.bbtxt.decodeAsParam());
  }
  if (a.qstr) {
    decode = a.qstr.decodeAsParam();
    if (query.boxed !== decode) {
      query.input(decode);
      query.fetch();
    }
    query.boxed = decode;
  }
  return TheApp;
};

m.route(document.getElementById('app'), '', {
  '': {
    onmatch: function(a, p) {
      return onMatch(a);
    }
  },
  '/:lang': {
    onmatch: function(a, p) {
      return onMatch(a);
    }
  },
  '/:lang/:qstr': {
    onmatch: function(a, p) {
      return onMatch(a);
    }
  },
  '/:lang/:qstr/:bbtxt': {
    onmatch: function(a, p) {
      return onMatch(a);
    }
  }
});
