extends Control
# JURAGAN KOST - by DieeDev

const NAMA := ["Rina", "Budi", "Sari", "Agus", "Dewi", "Joko", "Putri", "Eko", "Wulan", "Dimas"]
const PROFESI := {"Mahasiswa": 0.8, "Karyawan Pabrik": 1.2, "Perantau": 1.0, "Anak Magang": 0.9, "Pedagang": 1.1, "Guru Honorer": 1.0}
const HOBI := ["Nonton drakor", "Main gitar", "Gowes", "Mancing", "Masak", "Ngopi", "Push rank"]
const SAVE := "user://save.json"
const MAX_KAMAR := 8

var uang := 300000
var hari := 1
var rep := 0
var kamar: Array = []
var log_lines: Array = []
var cards: Array = []
var top: Label
var logl: Label
var list: VBoxContainer
var pop: PopupPanel
var pop_box: VBoxContainer
var th: Theme

func _ready() -> void:
    th = Theme.new()
    th.default_font_size = 26
    theme = th
    muat()
    if kamar.is_empty():
        for i in 4:
            kamar.append(baru_kamar())
    var root := VBoxContainer.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 16
    root.offset_top = 16
    root.offset_right = -16
    root.offset_bottom = -16
    root.add_theme_constant_override("separation", 10)
    add_child(root)
    top = Label.new()
    root.add_child(top)
    var sc := ScrollContainer.new()
    sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(sc)
    list = VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 10)
    sc.add_child(list)
    var bar := HBoxContainer.new()
    root.add_child(bar)
    bar.add_child(tombol("Cari Penyewa (Rp10.000)", cari))
    bar.add_child(tombol("Tambah Kamar", tambah_kamar))
    logl = Label.new()
    logl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    logl.custom_minimum_size = Vector2(0, 130)
    root.add_child(logl)
    pop = PopupPanel.new()
    pop.theme = th
    add_child(pop)
    var t := Timer.new()
    t.wait_time = 8.0
    t.autostart = true
    t.timeout.connect(hari_baru)
    add_child(t)
    bangun_list()
    pesan("Selamat datang, Juragan! Cari penyewa untuk kamar kosongmu.")

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED:
        simpan()

func baru_kamar() -> Dictionary:
    return {"lvl": 1, "token": 3, "tenant": null}

func tombol(teks: String, fn: Callable) -> Button:
    var b := Button.new()
    b.text = teks
    b.custom_minimum_size = Vector2(0, 80)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.pressed.connect(fn)
    return b

func rp(n: int) -> String:
    var s := str(abs(n))
    var out := ""
    while s.length() > 3:
        out = "." + s.substr(s.length() - 3) + out
        s = s.substr(0, s.length() - 3)
    return ("-" if n < 0 else "") + s + out

func sewa(k: Dictionary) -> int:
    if k.tenant == null:
        return 0
    return int((20000 + k.lvl * 15000) * k.tenant.mult)

func biaya_up(k: Dictionary) -> int:
    return 30000 * k.lvl * k.lvl

func bangun_list() -> void:
    for c in list.get_children():
        c.queue_free()
    cards.clear()
    for i in kamar.size():
        var p := PanelContainer.new()
        p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var v := VBoxContainer.new()
        p.add_child(v)
        var l := Label.new()
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        v.add_child(l)
        var h := HBoxContainer.new()
        v.add_child(h)
        var bu := tombol("", upgrade.bind(i))
        var bt := tombol("Isi Token Rp15.000", isi_token.bind(i))
        var bg := tombol("Tagih", tagih.bind(i))
        h.add_child(bu)
        h.add_child(bt)
        h.add_child(bg)
        list.add_child(p)
        cards.append({"l": l, "bu": bu, "bt": bt, "bg": bg})

func refresh() -> void:
    if cards.size() != kamar.size():
        return
    top.text = "Rp%s  |  Hari %d  |  Reputasi %d" % [rp(uang), hari, rep]
    for i in kamar.size():
        var k: Dictionary = kamar[i]
        var c: Dictionary = cards[i]
        var t = k.tenant
        var teks := "Kamar %d  (Lv %d)\n" % [i + 1, k.lvl]
        if t == null:
            teks += "Kosong"
        else:
            teks += "%s - %s (%s)\nPuas %d%%  |  Sewa Rp%s/hari  |  Token %d hari" % [t.nama, t.profesi, t.hobi, t.puas, rp(sewa(k)), k.token]
            if t.telat:
                teks += "\nTELAT BAYAR - tekan Tagih!"
        c.l.text = teks
        c.bu.text = ("Upgrade Rp" + rp(biaya_up(k))) if k.lvl < 5 else "Lv MAX"
        c.bu.disabled = k.lvl >= 5
        c.bt.disabled = t == null
        c.bg.disabled = t == null or not t.telat
    logl.text = "\n".join(log_lines)
    simpan()

func pesan(s: String) -> void:
    log_lines.append(s)
    while log_lines.size() > 4:
        log_lines.pop_front()
    refresh()

func cari() -> void:
    if uang < 10000:
        pesan("Uang tidak cukup untuk pasang iklan.")
        return
    var kosong := -1
    for i in kamar.size():
        if kamar[i].tenant == null:
            kosong = i
            break
    if kosong < 0:
        pesan("Semua kamar sudah terisi.")
        return
    uang -= 10000
    if pop_box:
        pop_box.queue_free()
    pop_box = VBoxContainer.new()
    pop_box.add_theme_constant_override("separation", 10)
    pop.add_child(pop_box)
    var jud := Label.new()
    jud.text = "Pilih calon penyewa (Kamar %d)" % (kosong + 1)
    pop_box.add_child(jud)
    for n in 3:
        var c := calon()
        var dep := int(30000 * c.mult)
        var b := tombol("%s - %s\nHobi: %s\nDeposit Rp%s  |  Sewa x%.1f" % [c.nama, c.profesi, c.hobi, rp(dep), c.mult], terima.bind(kosong, c))
        b.custom_minimum_size = Vector2(620, 110)
        pop_box.add_child(b)
    pop_box.add_child(tombol("Batal", pop.hide))
    pop.popup_centered(Vector2i(680, 620))
    refresh()

func calon() -> Dictionary:
    var pr: String = PROFESI.keys().pick_random()
    var m: float = PROFESI[pr] + randf_range(-0.05, 0.15) + rep * 0.002
    return {"nama": NAMA.pick_random(), "profesi": pr, "hobi": HOBI.pick_random(), "mult": snappedf(m, 0.1), "puas": 70, "telat": false}

func terima(i: int, c: Dictionary) -> void:
    var dep := int(30000 * c.mult)
    uang += dep
    kamar[i].tenant = c
    pop.hide()
    pesan("%s pindah ke Kamar %d (deposit Rp%s)." % [c.nama, i + 1, rp(dep)])

func upgrade(i: int) -> void:
    var k: Dictionary = kamar[i]
    var b := biaya_up(k)
    if uang < b:
        pesan("Uang kurang untuk upgrade Kamar %d." % (i + 1))
        return
    uang -= b
    k.lvl += 1
    if k.tenant != null:
        k.tenant.puas = min(100, k.tenant.puas + 10)
    pesan("Kamar %d naik ke Lv %d. Sewa makin mahal!" % [i + 1, k.lvl])

func isi_token(i: int) -> void:
    if uang < 15000:
        pesan("Uang kurang untuk beli token listrik.")
        return
    uang -= 15000
    kamar[i].token = min(kamar[i].token + 5, 10)
    pesan("Token listrik Kamar %d diisi." % (i + 1))

func tagih(i: int) -> void:
    var k: Dictionary = kamar[i]
    var t = k.tenant
    t.telat = false
    t.puas -= 5
    uang += sewa(k)
    pesan("%s akhirnya bayar sewa Kamar %d." % [t.nama, i + 1])

func tambah_kamar() -> void:
    var n := kamar.size()
    var biaya := 80000 * n
    var syarat := (n - 3) * 15
    if n >= MAX_KAMAR:
        pesan("Kost sudah maksimal %d kamar." % MAX_KAMAR)
    elif rep < syarat:
        pesan("Butuh reputasi %d untuk bangun kamar baru." % syarat)
    elif uang < biaya:
        pesan("Butuh Rp%s untuk bangun kamar baru." % rp(biaya))
    else:
        uang -= biaya
        kamar.append(baru_kamar())
        bangun_list()
        pesan("Kamar %d selesai dibangun!" % kamar.size())

func hari_baru() -> void:
    hari += 1
    var ada: Array = []
    for i in kamar.size():
        var k: Dictionary = kamar[i]
        var t = k.tenant
        if t == null:
            continue
        ada.append(i)
        k.token -= 1
        if k.token <= 0:
            k.token = 0
            t.puas -= 15
            pesan("Token listrik Kamar %d habis! %s kesal." % [i + 1, t.nama])
        else:
            t.puas = min(100, t.puas + k.lvl)
        if t.telat:
            t.puas -= 5
        elif t.puas < 55 and randf() < 0.4:
            t.telat = true
            pesan("%s telat bayar sewa (Kamar %d). Tagih!" % [t.nama, i + 1])
        else:
            uang += sewa(k)
            if t.puas >= 80:
                rep += 1
        if t.puas <= 0:
            pesan("%s pindah dari Kamar %d. Kamar kosong lagi." % [t.nama, i + 1])
            k.tenant = null
    if ada.size() > 0 and randf() < 0.15:
        var j: int = ada.pick_random()
        if kamar[j].tenant != null:
            kamar[j].tenant.puas -= 10
            pesan("Ada yang berisik dekat Kamar %d, penghuninya terganggu." % (j + 1))
    refresh()

func simpan() -> void:
    var f := FileAccess.open(SAVE, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"uang": uang, "hari": hari, "rep": rep, "kamar": kamar}))

func muat() -> void:
    if not FileAccess.file_exists(SAVE):
        return
    var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
    if typeof(d) != TYPE_DICTIONARY:
        return
    uang = int(d.uang)
    hari = int(d.hari)
    rep = int(d.rep)
    for k in d.kamar:
        var t = k.tenant
        if t != null:
            t.puas = int(t.puas)
            t.mult = float(t.mult)
        kamar.append({"lvl": int(k.lvl), "token": int(k.token), "tenant": t})
