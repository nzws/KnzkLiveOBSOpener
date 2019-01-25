// iniファイル操作モジュール
// https://wiki.hsp.moe/INI%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E6%93%8D%E4%BD%9C%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB.html
 
#ifndef IG_INI_FILE_MODULE_AS
#define IG_INI_FILE_MODULE_AS
 
// put で書き込み、get で読み込み
//	(s: 文字列, d: 小数, i: 整数)
 
#module mod_ini
 
#uselib "kernel32.dll"
#func   WritePrivateProfileString "WritePrivateProfileStringA" sptr,sptr,sptr,sptr
#func   GetPrivateProfileString   "GetPrivateProfileStringA"   sptr,sptr,sptr,int,int,sptr
#cfunc  GetPrivateProfileInt      "GetPrivateProfileIntA"      sptr,sptr,int,sptr
 
#define ctype double_to_str@mod_ini(%1) strf("\"%%.16e\"", %1)
#define null 0
 
/*-----------------------------------------------*
.* ini: ファイルパスを設定する
.* 
.* @prm path: ファイルパス
.*   (絶対パスか相対パスに限る。ファイル名のみではダメ。)
.*-----------------------------------------------*/
#deffunc ini_setpath str _path
    _ini_path = _path
    
    // 読み出し用のバッファを最小値で確保する
    sdim _strbuf, 512
    return
    
/*-----------------------------------------------*
.* ini: 値を書き込む
.*
.* @prm str section: セクション名
.* @prm str key:     キー名
.* @prm any value:   値 (文字列型に変換可能な型のみ)
.* 
.* @memo: 文字列型の値は "" で括った形で書き込むべき。
.*-----------------------------------------------*/
#define global ini_put(%1, %2, %3) ini_put_impl %1, %2, str(%3)
#deffunc ini_put_impl str sec, str key, str value
    WritePrivateProfileString sec, key, value, _ini_path
    return
    
// マクロ
#define global ini_puts(%1, %2, %3) ini_put_impl %1, %2, "\"" + (%3) + "\""
#define global ini_putd(%1, %2, %3) ini_put_impl %1, %2, double_to_str@mod_ini(%3)
#define global ini_puti ini_put
 
/*-----------------------------------------------*
.* ini: 値を読み込む
.*
.* 名前の最後に v がつくものは命令で、第一引数に変数をとる。
.* 　そうでないものは関数で、値は関数の返り値で返す。
.* 指定したキーが存在しない場合は、default に指定された値が返る。
.* 
.* @prm[var] dst:    (v) 受け取る変数 (文字列型でなければ初期化される)
.* @prm str section: セクション名
.* @prm str key:     キー名
.* @prm str default: 既定値 ("")
.* @prm int size:    読み込む文字数の最大 (∞)
.*-----------------------------------------------*/
// コア部分
// @ pSec, pKey を 実体, nullptr で切り替えて複数の操作をする。
#deffunc ini_getv_something_impl var dst, int pSec, int pKey, int pDef, int size_,  local size
    if ( vartype(dst) != 2 ) { sdim dst }
    size = limit(size_, 64, 0xFFFF)            // 最小でも 64 は確保する
    
*LReTry:
    // 読み出す分のバッファを確保
    memexpand dst, size
    
    // 読み込み
    GetPrivateProfileString pSec, pKey, pDef, varptr(dst), size, _ini_path
    
    // 文字数が足りなかった
    if ( (stat == size - 1 || stat == size - 2) && size_ <= 0 ) {
        size += size + 512        // バッファを拡大して取得し直す
        goto *LReTry
    }
    
    return
    
// 文字列
#define global ini_getsv(%1, %2, %3, %4 = "", %5 = 0) ini_getsv_ %1, %2, %3, %4, %5
#deffunc ini_getsv_ var dst, str sec_, str key_, str def_, int size_,  local sec, local key, local def
    sec = sec_
    key = key_
    def = def_
    ini_getv_something_impl dst, varptr(sec), varptr(key), varptr(def), size_
    return
    
#define global ctype ini_gets(%1, %2, %3 = "", %4 = 0) ini_gets_(%1, %2, %3, %4)
#defcfunc ini_gets_ str sec, str key, str def, int size_
    ini_getsv _strbuf, sec, key, def, size_
    return _strbuf
    
// 小数
#define global ini_getdv(%1, %2, %3, %4 = 0) %1 = ini_getd(%2, %3, %4)
 
#define global ctype ini_getd(%1, %2, %3 = 0) ini_getd_(%1, %2, %3)
#defcfunc ini_getd_ str sec, str key, double def
    ini_getsv _strbuf, sec, key, double_to_str@mod_ini(def), 32        // 32[byte]もあれば十分
    return double(_strbuf)
    
// 整数
#define global ini_getiv(%1, %2, %3, %4 = 0) %1 = ini_geti(%2, %3, %4)
 
#defcfunc ini_geti str sec, str key, int def
;	ini_getsv _strbuf, sec, key, str(def), 32
;	return int(_strbuf)
    return GetPrivateProfileInt( sec, key, def, _ini_path )
    
/*-----------------------------------------------*
.* ini: セクション, キーを列挙する
.*
.* @prm array dst:     受け取る変数(配列)
.* @prm[str]  section: セクション (enumKey の場合)
.* @prm int   size:    読み込む文字数の最大 (∞)
.*-----------------------------------------------*/
#deffunc ini_enumSection array dst_arr, int bufsize
    ini_getv_something_impl _strbuf, null, null, null, bufsize
    sdim dst_arr, stat
    SplitByNull dst_arr, _strbuf, stat
    return
    
#deffunc ini_enumKey array dst_arr, str section_, int bufsize,  local section
    section = section_
    ini_getv_something_impl _strbuf, varptr(section), null, null, bufsize
    sdim dst_arr, stat
    SplitByNull dst_arr, _strbuf, stat
    return
    
// cnv: '\0' 区切り文字列 -> 配列
#deffunc SplitByNull@mod_ini array dst, var buf, int maxsize,  local idx
    idx = 0
    sdim dst
    repeat
        if ( idx >= maxsize ) { break }        // (2013/10/23) コメント参照
        getstr dst(cnt), buf, idx, , maxsize
    ;	logmes dst(cnt)
        idx += strsize + 1
    loop
    return
    
#ifdef _DEBUG
// すべてのセクションのキーを列挙しデバッグ出力する
 #deffunc ini_dbglog  local seclist, local sec, local keylist, local key, local stmp
    logmes "\n(ini_dbglog): @" + _ini_path
    ini_enumSection seclist            // セクションを列挙
    
    foreach seclist : sec = seclist(cnt)
        logmes strf("[%s]", sec)
        ini_enumKey keylist, sec    // キーを列挙
        foreach keylist : key = keylist(cnt)
            ini_getsv stmp, sec, key, , 512
            logmes ("\t" + key + " = \"" + stmp + "\"")
        loop
    loop
    return
#else
 #define global ini_dbglog :
#endif
    
/*-----------------------------------------------*
.* ini: セクション, キーを削除する
.*
.* @prm str  section: セクション
.* @prm[str] key:     キー
.*-----------------------------------------------*/
#deffunc ini_removeSection str sec
    WritePrivateProfileString sec, null, null, _ini_path
    return
    
#deffunc ini_removeKey str sec, str key
    WritePrivateProfileString sec, key, null, _ini_path
    return
    
/*-----------------------------------------------*
.* ini: キーが存在するか否か
.*
.* @prm str section: セクション
.* @prm str key:     キー
.*-----------------------------------------------*/
#defcfunc ini_exists str sec, str key
    return ( ini_geti(sec, key, 0) == 0 && ini_geti(sec, key, 1) == 1 )
    
#global
 
#endif