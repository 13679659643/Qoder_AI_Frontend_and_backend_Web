// JScript for cscript.exe - Generate Power BI CSV data
// Reads data from HTML file to avoid encoding issues
// Usage: cscript //nologo generate_data.js

var fso = new ActiveXObject("Scripting.FileSystemObject");
var USD_RATE = 7.25;
var OUT_DIR = fso.GetParentFolderName(WScript.ScriptFullName);
var HTML_PATH = "C:\\Users\\jm043195\\Documents\\WXWork\\1688855609749784\\Cache\\File\\2026-04\\RL_\u63a8\u5e7f\u5468\u62a5_Dashboard.html";

// Read HTML and extract the D={...} and TTL={...} objects
var adoStream = new ActiveXObject("ADODB.Stream");
adoStream.Type = 2; // text
adoStream.Charset = "utf-8";
adoStream.Open();
adoStream.LoadFromFile(HTML_PATH);
var htmlContent = adoStream.ReadText();
adoStream.Close();

// Extract the D object and TTL
var scriptStart = htmlContent.indexOf("const D={");
var scriptBlock = htmlContent.substring(scriptStart);
// Find the D object - it ends before "const TTL="
var ttlStart = scriptBlock.indexOf("\nconst TTL=");
var dBlock = scriptBlock.substring(6, ttlStart); // skip "const "
var ttlLine = scriptBlock.substring(ttlStart + 7); // skip "\nconst "
var ttlEnd = ttlLine.indexOf(";");
var ttlBlock = ttlLine.substring(0, ttlEnd);

// Evaluate
eval("var " + dBlock);
eval("var " + ttlBlock);

// ========== HELPERS ==========
function r2(v) { return Math.round(v * 100) / 100; }
function r4(v) { return Math.round(v * 10000) / 10000; }
function toUSD(v) { return r2(v / USD_RATE); }
function vv(v) { return (v === null || v === undefined) ? '' : v; }
function pct(v) { return (v === null || v === undefined) ? '' : r4(v); }

function writeCSV(name, content) {
    var path = OUT_DIR + '\\' + name;
    var stream = new ActiveXObject("ADODB.Stream");
    stream.Type = 2;
    stream.Charset = "utf-8";
    stream.Open();
    stream.WriteText(content);
    stream.SaveToFile(path, 2); // overwrite
    stream.Close();
    WScript.Echo('Written: ' + name);
}

var NL = '\r\n';

// ========== 1. Overview KPI ==========
function genOverview() {
    var header = 'Channel,Currency,Cost,GMV,GMV_Pct,ROI,New_Invest_Pct,Orders,CPO,CR,Coupon,' +
        'Cost_Progress,Net_Sales,NS_Progress,Demand,Demand_Progress,New_Cost,Existing_Cost,DT,NT,' +
        'Cost_YoY,GMV_YoY,ROI_YoY,Orders_YoY,CPO_YoY,CR_YoY_pp,Demand_YoY,NS_YoY,' +
        'Target_GMV_Pct,Target_ROI,Target_CR';
    var rows = [header];
    var channels = ['TM', 'JD'];
    var currencies = ['RMB', 'USD'];

    for (var ci = 0; ci < channels.length; ci++) {
        var ch = channels[ci];
        var o = D[ch].ov;
        var y = D[ch].yoy;
        var t = D[ch].tgt;
        for (var ui = 0; ui < currencies.length; ui++) {
            var cur = currencies[ui];
            var isUSD = (cur === 'USD');
            var fxV = isUSD ? toUSD : function(v){return v;};
            rows.push([
                ch, cur,
                fxV(o.cost), fxV(o.gmv), pct(o.gmvPct), r2(o.roi), pct(o.newPct),
                o.orders, r2(fxV(o.cpo)), pct(o.cr), fxV(o.coupon),
                pct(o.cp), fxV(o.ns), pct(o.np), fxV(o.demand), pct(o.dp),
                fxV(o.nc), fxV(o.ec), fxV(o.dt), fxV(o.nt),
                pct(y.cost), pct(y.gmv), pct(y.roi), pct(y.orders), pct(y.cpo),
                pct(y.cr), pct(y.demand), pct(y.ns),
                pct(t.gmvPct), r2(t.roi), pct(t.cr)
            ].join(','));
        }
    }

    // TTL rows
    var ttlNs = D.TM.ov.ns + D.JD.ov.ns;
    var ttlDemand = D.TM.ov.demand + D.JD.ov.demand;
    var ttlNc = D.TM.ov.nc + D.JD.ov.nc;
    var ttlEc = D.TM.ov.ec + D.JD.ov.ec;
    var ttlDt = D.TM.ov.dt + D.JD.ov.dt;
    var ttlNt = D.TM.ov.nt + D.JD.ov.nt;
    var ttlCoupon = D.TM.ov.coupon + D.JD.ov.coupon;

    for (var ui = 0; ui < currencies.length; ui++) {
        var cur = currencies[ui];
        var isUSD = (cur === 'USD');
        var fxV = isUSD ? toUSD : function(v){return v;};
        rows.push([
            'TTL', cur,
            fxV(TTL.cost), fxV(TTL.gmv), pct(TTL.gmvPct), r2(TTL.roi), pct(TTL.newPct),
            TTL.orders, r2(fxV(TTL.cpo)), pct(TTL.cr), fxV(ttlCoupon),
            pct(TTL.cp), fxV(ttlNs), pct(TTL.np), fxV(ttlDemand), pct(TTL.dp),
            fxV(ttlNc), fxV(ttlEc), fxV(ttlDt), fxV(ttlNt),
            '', '', '', '', '', '', '', '',
            '', '', ''
        ].join(','));
    }

    writeCSV('01_Overview_KPI.csv', rows.join(NL));
}

// ========== 2. Media Matrix ==========
function genMedia() {
    var header = 'Channel,Currency,Media_Name,Is_SubTotal,Is_GrandTotal,' +
        'Cost,Cost_Pct,IMP,Click,Cart,Orders,GMV,CTR,CPC,CPA,CVR,AOV,ROI,' +
        'Cost_YoY,IMP_YoY,Click_YoY,Cart_YoY,Orders_YoY,GMV_YoY,CTR_YoY,CPC_YoY,CPA_YoY,CVR_YoY,AOV_YoY,ROI_YoY';
    var rows = [header];
    var channels = ['TM', 'JD'];
    var currencies = ['RMB', 'USD'];

    for (var ci = 0; ci < channels.length; ci++) {
        var ch = channels[ci];
        var media = D[ch].media;
        var myoy = D[ch].myoy;
        for (var ui = 0; ui < currencies.length; ui++) {
            var cur = currencies[ui];
            var isUSD = (cur === 'USD');
            for (var mi = 0; mi < media.length; mi++) {
                var m = media[mi];
                var y = myoy[mi];
                rows.push([
                    ch, cur, '"' + m.n + '"',
                    m.sub ? 1 : 0,
                    m.ttl ? 1 : 0,
                    isUSD ? toUSD(m.cost) : m.cost,
                    pct(m.cp),
                    m.imp, m.click, m.cart, m.ord,
                    isUSD ? toUSD(m.gmv) : m.gmv,
                    pct(m.ctr),
                    isUSD ? r2(m.cpc / USD_RATE) : r2(m.cpc),
                    isUSD ? r2(m.cpa / USD_RATE) : r2(m.cpa),
                    pct(m.cvr),
                    isUSD ? r2(m.aov / USD_RATE) : m.aov,
                    r2(m.roi),
                    pct(y.cost), pct(y.imp), pct(y.click), pct(y.cart),
                    pct(y.ord), pct(y.gmv), pct(y.ctr), pct(y.cpc),
                    pct(y.cpa), pct(y.cvr), pct(y.aov), pct(y.roi)
                ].join(','));
            }
        }
    }
    writeCSV('02_Media_Matrix.csv', rows.join(NL));
}

// ========== 3. Keywords ==========
function genKeywords() {
    var header = 'Channel,Currency,Level,Parent_Category,Keyword,' +
        'Cost,Cost_Pct,IMP,Click,Cart,Orders,GMV,CVR,CTR,CPC,Cart_Cost,ROI';
    var rows = [header];
    var channels = ['TM', 'JD'];
    var currencies = ['RMB', 'USD'];

    for (var ci = 0; ci < channels.length; ci++) {
        var ch = channels[ci];
        var kws = D[ch].kw;
        for (var ui = 0; ui < currencies.length; ui++) {
            var cur = currencies[ui];
            var isUSD = (cur === 'USD');
            for (var ki = 0; ki < kws.length; ki++) {
                var k = kws[ki];
                var isTotal = (k.n === 'Total');
                rows.push([
                    ch, cur, isTotal ? 'Total' : 'Category', '', '"' + k.n + '"',
                    isUSD ? toUSD(k.cost) : k.cost,
                    pct(k.cp),
                    vv(k.imp), vv(k.click), vv(k.cart), vv(k.ord),
                    isUSD ? toUSD(k.gmv) : k.gmv,
                    pct(k.cvr), pct(k.ctr),
                    isUSD ? r2(k.cpc / USD_RATE) : r2(k.cpc),
                    isUSD ? r2(k.cc / USD_RATE) : r2(k.cc),
                    r2(k.roi)
                ].join(','));
                if (k.kids) {
                    for (var j = 0; j < k.kids.length; j++) {
                        var c = k.kids[j];
                        var childRoi = (c.gmv && c.cost) ? r2(c.gmv / c.cost) : '';
                        rows.push([
                            ch, cur, 'Keyword', '"' + k.n + '"', '"' + c.n + '"',
                            isUSD ? toUSD(c.cost) : c.cost,
                            '',
                            '', vv(c.click), vv(c.cart), vv(c.ord),
                            isUSD ? toUSD(c.gmv) : c.gmv,
                            '', '', '', '',
                            childRoi
                        ].join(','));
                    }
                }
            }
        }
    }
    writeCSV('03_Keywords.csv', rows.join(NL));
}

// ========== 4. Crowd ==========
function genCrowd() {
    var header = 'Channel,Currency,Level1,Level2,Level3,Crowd_Name,' +
        'Cost,Cost_Pct,IMP,Click,Cart,Orders,GMV,CTR,CPC,CVR,Cart_Cost,ROI';
    var rows = [header];
    var channels = ['TM', 'JD'];
    var currencies = ['RMB', 'USD'];

    for (var ci = 0; ci < channels.length; ci++) {
        var ch = channels[ci];
        var crowd = D[ch].crowd;
        for (var ui = 0; ui < currencies.length; ui++) {
            var cur = currencies[ui];
            var isUSD = (cur === 'USD');

            for (var gi = 0; gi < crowd.length; gi++) {
                var g = crowd[gi];
                rows.push([
                    ch, cur,
                    '"' + g.n + '"', '', '', '"' + g.n + '"',
                    isUSD ? toUSD(g.cost) : g.cost,
                    pct(g.cp),
                    vv(g.imp), vv(g.click), vv(g.cart), vv(g.ord),
                    isUSD ? toUSD(g.gmv) : g.gmv,
                    pct(g.ctr),
                    g.cpc ? (isUSD ? r2(g.cpc/USD_RATE) : r2(g.cpc)) : '',
                    pct(g.cvr),
                    g.cc ? (isUSD ? r2(g.cc/USD_RATE) : r2(g.cc)) : '',
                    g.roi ? r2(g.roi) : ''
                ].join(','));

                if (g.kids) {
                    for (var si = 0; si < g.kids.length; si++) {
                        var s = g.kids[si];
                        rows.push([
                            ch, cur,
                            '"' + g.n + '"', '"' + s.n + '"', '', '"' + s.n + '"',
                            isUSD ? toUSD(s.cost) : s.cost,
                            s.cp !== undefined ? pct(s.cp) : '',
                            vv(s.imp), vv(s.click), vv(s.cart), vv(s.ord),
                            isUSD ? toUSD(s.gmv) : s.gmv,
                            pct(s.ctr),
                            s.cpc ? (isUSD ? r2(s.cpc/USD_RATE) : r2(s.cpc)) : '',
                            pct(s.cvr),
                            s.cc ? (isUSD ? r2(s.cc/USD_RATE) : r2(s.cc)) : '',
                            s.roi ? r2(s.roi) : ''
                        ].join(','));

                        if (s.kids) {
                            for (var ti = 0; ti < s.kids.length; ti++) {
                                var t = s.kids[ti];
                                rows.push([
                                    ch, cur,
                                    '"' + g.n + '"', '"' + s.n + '"', '"' + t.n + '"', '"' + t.n + '"',
                                    isUSD ? toUSD(t.cost) : t.cost,
                                    '',
                                    '', '', vv(t.cart), vv(t.ord),
                                    isUSD ? toUSD(t.gmv) : t.gmv,
                                    '', '', '', '',
                                    (t.gmv && t.cost) ? r2(t.gmv / t.cost) : ''
                                ].join(','));
                            }
                        }
                    }
                }
            }
        }
    }
    writeCSV('04_Crowd.csv', rows.join(NL));
}

// ========== 5. Category Breakthrough ==========
function genCategory() {
    var header = 'Channel,Currency,View_Type,Label,Parent_Label,EOH_Pct,Active_IDs,NS_Pct,Demand_Pct,' +
        'Cost,Cost_Pct,Cart_Cost,ROI,' +
        'IDs_WoW,NS_WoW,Cost_WoW,CostPct_WoW,CartCost_WoW,ROI_WoW';
    var rows = [header];
    var channels = ['TM', 'JD'];
    var currencies = ['RMB', 'USD'];
    var viewTypes = [
        {key: 'catS', name: 'Super_Season'},
        {key: 'catL', name: 'Label'},
        {key: 'catF', name: 'Framework'}
    ];

    for (var ci = 0; ci < channels.length; ci++) {
        var ch = channels[ci];
        for (var ui = 0; ui < currencies.length; ui++) {
            var cur = currencies[ui];
            var isUSD = (cur === 'USD');

            for (var vi = 0; vi < viewTypes.length; vi++) {
                var vt = viewTypes[vi];
                var data = D[ch][vt.key];
                for (var ri = 0; ri < data.length; ri++) {
                    var r = data[ri];
                    var w = r.wow || {};
                    rows.push([
                        ch, cur, vt.name,
                        '"' + r.l + '"', '',
                        pct(r.eoh), r.ids, pct(r.ns), pct(r.ds),
                        isUSD ? toUSD(r.cost) : r.cost,
                        pct(r.cp),
                        isUSD ? r2(r.cc / USD_RATE) : r2(r.cc),
                        r2(r.roi),
                        w.ids !== undefined ? pct(w.ids) : '',
                        w.ns !== undefined ? pct(w.ns) : '',
                        w.cost !== undefined ? pct(w.cost) : '',
                        w.cp !== undefined ? pct(w.cp) : '',
                        w.cc !== undefined ? pct(w.cc) : '',
                        w.roi !== undefined ? pct(w.roi) : ''
                    ].join(','));
                }
            }

            // catLC (hierarchical)
            var lcData = D[ch].catLC;
            for (var gi = 0; gi < lcData.length; gi++) {
                var g = lcData[gi];
                var gw = g.wow || {};
                rows.push([
                    ch, cur, 'Label_x_Category',
                    '"' + g.l + '"', '',
                    pct(g.eoh), g.ids, pct(g.ns), pct(g.ds),
                    isUSD ? toUSD(g.cost) : g.cost,
                    pct(g.cp),
                    isUSD ? r2(g.cc / USD_RATE) : r2(g.cc),
                    r2(g.roi),
                    gw.ids !== undefined ? pct(gw.ids) : '',
                    gw.ns !== undefined ? pct(gw.ns) : '',
                    gw.cost !== undefined ? pct(gw.cost) : '',
                    gw.cp !== undefined ? pct(gw.cp) : '',
                    gw.cc !== undefined ? pct(gw.cc) : '',
                    gw.roi !== undefined ? pct(gw.roi) : ''
                ].join(','));
                if (g.kids) {
                    for (var ki = 0; ki < g.kids.length; ki++) {
                        var k = g.kids[ki];
                        var kw = k.wow || {};
                        rows.push([
                            ch, cur, 'Label_x_Category',
                            '"' + k.l + '"', '"' + g.l + '"',
                            pct(k.eoh), k.ids, pct(k.ns), pct(k.ds),
                            isUSD ? toUSD(k.cost) : k.cost,
                            pct(k.cp),
                            isUSD ? r2(k.cc / USD_RATE) : r2(k.cc),
                            r2(k.roi),
                            kw.ids !== undefined ? pct(kw.ids) : '',
                            kw.ns !== undefined ? pct(kw.ns) : '',
                            kw.cost !== undefined ? pct(kw.cost) : '',
                            kw.cp !== undefined ? pct(kw.cp) : '',
                            kw.cc !== undefined ? pct(kw.cc) : '',
                            kw.roi !== undefined ? pct(kw.roi) : ''
                        ].join(','));
                    }
                }
            }
        }
    }
    writeCSV('05_Category_Breakthrough.csv', rows.join(NL));
}

// ========== 6. Fee Detail ==========
function genFeeDetail() {
    var header = 'Channel,Currency,Platform,Section,Classification,Sub_Channel,Fee,Fee_Ratio,Is_SubTotal';
    var rows = [header];
    var currencies = ['RMB', 'USD'];

    var feeData = {
        TM: [
            {p:'TM',bk:'\u4ed8\u8d39',fl:'\u54c1\u9500\u5b9d',ch:'Brand Zone',cost:549134.47,cr:0.020472,ttl:0},
            {p:'',bk:'',fl:'',ch:'Brand Star',cost:0,cr:0,ttl:0},
            {p:'',bk:'',fl:'\u54c1\u9500\u5b9d TTL',ch:'',cost:549134.47,cr:0.020472,ttl:1},
            {p:'',bk:'',fl:'RTB',ch:'RTB',cost:1766491.60,cr:0.065856,ttl:0},
            {p:'',bk:'',fl:'JCGP',ch:'Brand Display',cost:1077500,cr:0.04017,ttl:0},
            {p:'',bk:'',fl:'',ch:'UD Brand',cost:0,cr:0,ttl:0},
            {p:'',bk:'',fl:'',ch:'TOPSHOW',cost:0,cr:0,ttl:0},
            {p:'',bk:'',fl:'',ch:'UD Performance',cost:0,cr:0,ttl:0},
            {p:'',bk:'',fl:'',ch:'Brand Showmax',cost:0,cr:0.04017,ttl:0},
            {p:'',bk:'',fl:'JCGP TTL',ch:'',cost:1077500,cr:0.04017,ttl:1},
            {p:'',bk:'\u4ed8\u8d39TTL',fl:'',ch:'',cost:3393126.07,cr:0.126498,ttl:1},
            {p:'',bk:'\u77ed\u4fe1',fl:'',ch:'',cost:0,cr:0,ttl:0},
            {p:'',bk:'\u77ed\u89c6\u9891\u62cd\u6444',fl:'',ch:'',cost:0,cr:0,ttl:0},
            {p:'',bk:'\u5176\u5b83',fl:'',ch:'',cost:0,cr:0,ttl:0},
            {p:'TM TTL',bk:'',fl:'',ch:'',cost:3393126.07,cr:0.126498,ttl:1}
        ],
        JD: [
            {p:'JD',bk:'\u4ed8\u8d39',fl:'\u54c1\u724c\u4e13\u533a',ch:'Search Brand',cost:48686.70,cr:0.009927,ttl:0},
            {p:'',bk:'',fl:'RTB',ch:'RTB',cost:479266.10,cr:0.097719,ttl:0},
            {p:'',bk:'',fl:'\u5546\u52a1\u91c7\u4e70',ch:'',cost:0,cr:0,ttl:0},
            {p:'',bk:'\u4ed8\u8d39TTL',fl:'',ch:'',cost:527952.80,cr:0.107646,ttl:1},
            {p:'',bk:'\u77ed\u4fe1',fl:'',ch:'',cost:0,cr:0,ttl:0},
            {p:'',bk:'\u5176\u5b83',fl:'',ch:'',cost:0,cr:0,ttl:0},
            {p:'JD TTL',bk:'',fl:'',ch:'',cost:527952.80,cr:0.107646,ttl:1}
        ]
    };

    var chs = ['TM', 'JD'];
    for (var ci = 0; ci < chs.length; ci++) {
        var ch = chs[ci];
        var fees = feeData[ch];
        for (var ui = 0; ui < currencies.length; ui++) {
            var cur = currencies[ui];
            var isUSD = (cur === 'USD');
            for (var fi = 0; fi < fees.length; fi++) {
                var f = fees[fi];
                rows.push([
                    ch, cur,
                    '"' + f.p + '"', '"' + f.bk + '"', '"' + f.fl + '"', '"' + f.ch + '"',
                    isUSD ? toUSD(f.cost) : r2(f.cost),
                    pct(f.cr),
                    f.ttl
                ].join(','));
            }
        }
    }
    writeCSV('06_Fee_Detail.csv', rows.join(NL));
}

// ========== EXECUTE ==========
WScript.Echo('=== Generating Power BI Data Files ===');
WScript.Echo('Output: ' + OUT_DIR);
WScript.Echo('');

genOverview();
genMedia();
genKeywords();
genCrowd();
genCategory();
genFeeDetail();

WScript.Echo('');
WScript.Echo('=== All 6 CSV files generated! ===');
