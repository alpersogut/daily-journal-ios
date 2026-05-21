import SwiftUI
import AVKit

// 1. VERİ MODELİMİZ
struct Kayit: Identifiable {
    let id = UUID()
    let tarih: Date
    var baslik: String
    var fotolar: [UIImage] = []
    var videolar: [URL] = []
    var videoKapaklari: [UIImage] = []
    var sesYolu: URL?
    
    var tarihMetin: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: tarih)
    }
}

// 2. YENİ TASARIMLI ANA EKRAN (Polaroid Galeri)
struct ContentView: View {
    @State private var kayitlar: [Kayit] = []
    @State private var yeniKayitAc = false
    @State private var uyariGoster = false
    
    var mevcutStreak: Int {
        guard !kayitlar.isEmpty else { return 0 }
        let calendar = Calendar.current
        let bugun = calendar.startOfDay(for: Date())
        let gunler = Array(Set(kayitlar.map { calendar.startOfDay(for: $0.tarih) })).sorted(by: >)
        
        var seri = 0
        var beklenenGun = bugun
        
        if gunler.first != bugun {
            beklenenGun = calendar.date(byAdding: .day, value: -1, to: bugun)!
        }
        
        for gun in gunler {
            if gun == beklenenGun {
                seri += 1
                beklenenGun = calendar.date(byAdding: .day, value: -1, to: beklenenGun)!
            } else {
                break
            }
        }
        return seri
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan rengi (Açık gri)
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // STREAK (SERİ) BANNER'I - Modern Tasarım
                    if mevcutStreak >= 3 {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle().fill(Color.orange.opacity(0.2)).frame(width: 40, height: 40)
                                Image(systemName: "flame.fill").foregroundStyle(.orange).font(.title3)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(mevcutStreak) Günlük Seri!").font(.headline).bold().foregroundStyle(.orange)
                                Text("Ateşi harlamaya devam et.").font(.caption).foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                    }
                    
                    if kayitlar.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "camera.filters")
                                .font(.system(size: 70))
                                .foregroundStyle(.gray.opacity(0.3))
                            Text("Anı Odası Boş")
                                .font(.title2).bold().foregroundStyle(.gray)
                            Text("İlk anınızı ölümsüzleştirmek için\nsağ üstteki + butonuna dokunun.")
                                .font(.subheadline).foregroundStyle(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    } else {
                        // KART LİSTESİ (Gizli satır çizgileriyle)
                        List {
                            ForEach(kayitlar) { kayit in
                                ZStack {
                                    // Özel Tasarım Polaroid Kartı
                                    KayitKartiView(kayit: kayit)
                                    
                                    // Görünmez NavigationLink (Sağdaki varsayılan oku gizlemek için)
                                    NavigationLink(destination: KayitDetayView(kayit: kayit)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                }
                                .listRowSeparator(.hidden) // Çizgileri kaldır
                                .listRowBackground(Color.clear) // Satır arka planını şeffaf yap
                                .padding(.vertical, 6)
                            }
                            .onDelete { kayitlar.remove(atOffsets: $0) }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("📆 Günlüğüm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    let bugunKayitVarMi = kayitlar.contains { Calendar.current.isDateInToday($0.tarih) }
                    if bugunKayitVarMi { uyariGoster = true } else { yeniKayitAc = true }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .alert("Bugün Zaten Kayıt Yaptın!", isPresented: $uyariGoster) {
                Button("Tamam", role: .cancel) { }
            } message: { Text("Günde sadece bir kez kayıt yapabilirsin. Yarına kadar bekle!") }
            .sheet(isPresented: $yeniKayitAc) {
                YeniKayitView { yeniKayit in kayitlar.insert(yeniKayit, at: 0) }
            }
        }
    }
}

// POLAROID KART TASARIMI (Yeni Alt Görünüm)
struct KayitKartiView: View {
    let kayit: Kayit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MEDYA ALANI (Fotoğraf, Video veya Boşluk)
            if let ilkFoto = kayit.fotolar.first {
                Image(uiImage: ilkFoto)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
            } else if let ilkKapak = kayit.videoKapaklari.first {
                ZStack {
                    Image(uiImage: ilkKapak)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                    Color.black.opacity(0.3)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                }
            } else {
                // Medya yoksa renkli bir degrade arka plan
                LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 120)
            }
            
            // METİN VE BİLGİ ALANI
            VStack(alignment: .leading, spacing: 8) {
                Text(kayit.tarihMetin)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                
                Text(kayit.baslik)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                // EKSTRA MEDYA İKONLARI (Eğer birden fazla medya veya ses varsa göster)
                HStack(spacing: 12) {
                    if kayit.fotolar.count > 1 {
                        Label("\(kayit.fotolar.count)", systemImage: "photo.on.rectangle")
                    }
                    if !kayit.videolar.isEmpty {
                        Label("\(kayit.videolar.count)", systemImage: "video.fill")
                    }
                    if kayit.sesYolu != nil {
                        Image(systemName: "mic.fill").foregroundStyle(.blue)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .cornerRadius(20) // Köşeleri yuvarla
        .shadow(color: .black.opacity(0.12), radius: 15, x: 0, y: 8) // Şık bir gölge ekle
    }
}

// 3. YENİ KAYIT EKRANI
struct YeniKayitView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var recorder = AudioRecorder()
    
    @State private var baslik = ""
    @State private var fotografAcik = false
    @State private var videoAcik = false
    
    @State private var cekilenFotolar: [UIImage] = []
    @State private var cekilenVideolar: [URL] = []
    @State private var cekilenVideoKapaklari: [UIImage] = []
    
    @State private var anlikFoto: UIImage? = nil
    @State private var anlikVideoYolu: URL? = nil
    @State private var anlikVideoKapak: UIImage? = nil
    
    @State private var yapayZekaIsliyor = false
    let kaydetme: (Kayit) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Başlık") { TextField("Bugün nasıldı?", text: $baslik) }
                
                Section("Medya") {
                    if yapayZekaIsliyor {
                        VStack {
                            ProgressView().scaleEffect(1.5)
                            Text("Yapay Zeka Yüzü Odaklıyor...").font(.caption).foregroundStyle(.gray).padding(.top, 8)
                        }.frame(maxWidth: .infinity, alignment: .center).padding()
                    }
                    
                    if !cekilenFotolar.isEmpty || !cekilenVideolar.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<cekilenFotolar.count, id: \.self) { i in
                                    Image(uiImage: cekilenFotolar[i]).resizable().scaledToFill().frame(width: 120, height: 120).cornerRadius(10).clipped()
                                }
                                ForEach(0..<cekilenVideoKapaklari.count, id: \.self) { i in
                                    ZStack {
                                        Image(uiImage: cekilenVideoKapaklari[i]).resizable().scaledToFill().frame(width: 120, height: 120).cornerRadius(10).clipped()
                                        Image(systemName: "play.circle.fill").foregroundStyle(.white).font(.title)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button("Fotoğraf Çek / Seç") { fotografAcik = true }
                    Button("Video Çek") { videoAcik = true }
                }
                
                Section("Ses Kaydı") {
                    Button(recorder.kayitYapiliyor ? "Kaydı Durdur" : "Kayıt Başlat") {
                        recorder.kayitYapiliyor ? recorder.kayitDurdur() : recorder.kayitBaslat()
                    }.foregroundStyle(recorder.kayitYapiliyor ? .red : .blue)
                    if recorder.kayitVar { Button("Kaydı Oynat") { recorder.kayitOynat() } }
                }
            }
            .navigationTitle("Yeni Kayıt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let sesYolu = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("kayit.m4a")
                        let kayit = Kayit(
                            tarih: Date(),
                            baslik: baslik,
                            fotolar: cekilenFotolar,
                            videolar: cekilenVideolar,
                            videoKapaklari: cekilenVideoKapaklari,
                            sesYolu: recorder.kayitVar ? sesYolu : nil
                        )
                        kaydetme(kayit)
                        dismiss()
                    }.disabled(baslik.isEmpty || yapayZekaIsliyor)
                }
            }
            .sheet(isPresented: $fotografAcik) { FotografCekici(image: $anlikFoto) }
            .sheet(isPresented: $videoAcik) { VideoCekici(videoURL: $anlikVideoYolu, videoKapak: $anlikVideoKapak) }
            .onChange(of: anlikFoto) { yeniFoto in
                if let foto = yeniFoto {
                    yapayZekaIsliyor = true
                    NetworkManager.shared.fotografiIsle(foto: foto) { islenmisFoto in
                        yapayZekaIsliyor = false
                        cekilenFotolar.append(islenmisFoto ?? foto)
                        anlikFoto = nil
                    }
                }
            }
            .onChange(of: anlikVideoYolu) { yeniVideo in
                if let video = yeniVideo, let kapak = anlikVideoKapak {
                    cekilenVideolar.append(video)
                    cekilenVideoKapaklari.append(kapak)
                    anlikVideoYolu = nil
                    anlikVideoKapak = nil
                }
            }
        }
    }
}

// 4. KAYIT DETAY EKRANI
struct KayitDetayView: View {
    let kayit: Kayit
    @StateObject private var recorder = AudioRecorder()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(kayit.tarihMetin).font(.caption).foregroundStyle(.gray)
                Text(kayit.baslik).font(.title2).bold()
                
                ForEach(0..<kayit.fotolar.count, id: \.self) { i in
                    Image(uiImage: kayit.fotolar[i]).resizable().scaledToFit().cornerRadius(12)
                }
                
                ForEach(0..<kayit.videolar.count, id: \.self) { i in
                    VideoPlayer(player: AVPlayer(url: kayit.videolar[i])).frame(height: 300).cornerRadius(12)
                }
                
                if kayit.sesYolu != nil {
                    Button { recorder.kayitOynat() } label: { Label("Ses Kaydını Oynat", systemImage: "play.circle.fill").font(.title3) }
                }
            }.padding()
        }.navigationTitle("Kayıt Detayı")
    }
}
