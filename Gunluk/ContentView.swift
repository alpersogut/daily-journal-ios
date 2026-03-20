import SwiftUI
import AVKit

struct Kayit: Identifiable {
    let id = UUID()
    let tarih: Date
    var baslik: String
    var foto: UIImage?
    var sesYolu: URL?
    var videoYolu: URL?
    var videoKapak: UIImage?
    
    var tarihMetin: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: tarih)
    }
}

struct ContentView: View {
    @State private var kayitlar: [Kayit] = []
    @State private var yeniKayitAc = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if kayitlar.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray.opacity(0.5))
                        Text("Henüz kayıt yok.")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.gray)
                        Text("+ butonuna basarak\nilk günlük kaydınızı oluşturun.")
                            .font(.subheadline)
                            .foregroundStyle(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        ForEach(kayitlar) { kayit in
                            NavigationLink(destination: KayitDetayView(kayit: kayit)) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(kayit.tarihMetin)
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                            .lineLimit(1)
                                        Text(kayit.baslik)
                                            .font(.headline)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if kayit.sesYolu != nil {
                                            Label("Ses kaydı var", systemImage: "mic.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.blue)
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    HStack(spacing: 4) {
                                        if let foto = kayit.foto {
                                            Image(uiImage: foto)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 75, height: 75)
                                                .cornerRadius(8)
                                                .clipped()
                                        }
                                        if let kapak = kayit.videoKapak {
                                            ZStack {
                                                Image(uiImage: kapak)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 75, height: 75)
                                                    .cornerRadius(8)
                                                    .clipped()
                                                Image(systemName: "play.circle.fill")
                                                    .foregroundStyle(.white)
                                                    .font(.title2)
                                            }
                                        }
                                    }
                                }
                                .padding(14)
                                .background(Color(.systemBackground))
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                            }
                        }
                        .onDelete { indexSet in
                            kayitlar.remove(atOffsets: indexSet)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("📆 Günlüğüm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    yeniKayitAc = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $yeniKayitAc) {
                YeniKayitView { yeniKayit in
                    kayitlar.insert(yeniKayit, at: 0)
                }
            }
        }
    }
}

struct YeniKayitView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var recorder = AudioRecorder()
    @State private var baslik = ""
    @State private var fotografAcik = false
    @State private var videoAcik = false
    @State private var cekigenFoto: UIImage? = nil
    @State private var videoYolu: URL? = nil
    @State private var videoKapak: UIImage? = nil
    let kaydetme: (Kayit) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Başlık") {
                    TextField("Bugün nasıldı?", text: $baslik)
                }
                
                Section("Medya") {
                    if let foto = cekigenFoto {
                        Image(uiImage: foto)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(10)
                    }
                    if let kapak = videoKapak {
                        ZStack {
                            Image(uiImage: kapak)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(10)
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 50))
                        }
                    }
                    
                    Button("Fotoğraf Çek") {
                        fotografAcik = true
                    }
                    
                    Button("Video Çek") {
                        videoAcik = true
                    }
                }
                
                Section("Ses Kaydı") {
                    Button(recorder.kayitYapiliyor ? "Kaydı Durdur" : "Kayıt Başlat") {
                        if recorder.kayitYapiliyor {
                            recorder.kayitDurdur()
                        } else {
                            recorder.kayitBaslat()
                        }
                    }
                    .foregroundStyle(recorder.kayitYapiliyor ? .red : .blue)
                    
                    if recorder.kayitVar {
                        Button("Kaydı Oynat") {
                            recorder.kayitOynat()
                        }
                    }
                }
            }
            .navigationTitle("Yeni Kayıt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let sesYolu = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            .appendingPathComponent("kayit.m4a")
                        let kayit = Kayit(
                            tarih: Date(),
                            baslik: baslik,
                            foto: cekigenFoto,
                            sesYolu: recorder.kayitVar ? sesYolu : nil,
                            videoYolu: videoYolu,
                            videoKapak: videoKapak
                        )
                        kaydetme(kayit)
                        dismiss()
                    }
                    .disabled(baslik.isEmpty)
                }
            }
            .sheet(isPresented: $fotografAcik) {
                FotografCekici(image: $cekigenFoto)
            }
            .sheet(isPresented: $videoAcik) {
                VideoCekici(videoURL: $videoYolu, videoKapak: $videoKapak)
            }
        }
    }
}

struct KayitDetayView: View {
    let kayit: Kayit
    @StateObject private var recorder = AudioRecorder()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(kayit.tarihMetin)
                    .font(.caption)
                    .foregroundStyle(.gray)
                
                Text(kayit.baslik)
                    .font(.title2)
                    .bold()
                
                if let foto = kayit.foto {
                    Image(uiImage: foto)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                }
                
                if let videoYolu = kayit.videoYolu {
                    VideoPlayer(player: AVPlayer(url: videoYolu))
                        .frame(height: 300)
                        .cornerRadius(12)
                }
                
                if kayit.sesYolu != nil {
                    Button {
                        recorder.kayitOynat()
                    } label: {
                        Label("Ses Kaydını Oynat", systemImage: "play.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Kayıt Detayı")
    }
}
