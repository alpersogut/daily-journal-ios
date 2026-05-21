import Foundation // Temel veri işlemleri için gerekli
import UIKit      // Fotoğraf (UIImage) sınıfı için gerekli

class NetworkManager {
    static let shared = NetworkManager() // Uygulama içinde tek bir kurye olmasını sağlar
    
    // Senin terminalde bulduğun gerçek Ubuntu IP adresi:
    let sunucuURL = "http://192.168.1.119:8000/fotograf-isle"

    func fotografiIsle(foto: UIImage, completion: @escaping (UIImage?) -> Void) {
        // Yazdığımız adresin geçerli bir URL olup olmadığını kontrol eder
        guard let url = URL(string: sunucuURL) else {
            completion(nil) // Hatalıysa boş dön
            return
        }

        // İnternet paketini hazırlar
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // Veri göndereceğimiz için POST yöntemini kullanır
        
        // Fotoğrafı parçalara ayırmak için rastgele bir sınır şifresi oluşturur
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // UIImage formatındaki fotoğrafı, internetten gidebilecek Data (bayt) formatına çevirir
        guard let imageData = foto.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }

        // Gönderilecek kargo paketinin içeriğini oluşturmaya başlar
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!) // Sınırı başlatır
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"foto.jpg\"\r\n".data(using: .utf8)!) // Dosya ismini söyler
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!) // Dosya türünü belirtir
        body.append(imageData) // Fotoğrafın asıl verisini pakete koyar
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!) // Paketi kapatır

        // Paketi Ubuntu'ya fırlatır ve cevabı bekler
        URLSession.shared.uploadTask(with: request, from: body) { responseData, response, error in
            // Bağlantı hatası varsa buraya düşer
            if let error = error {
                print("Ağ Hatası: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Sunucudan 200 (Başarılı) kodu geldiyse ve veri boş değilse devam eder
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let responseData = responseData else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Ubuntu'dan gelen kırpılmış baytları tekrar fotoğrafa (UIImage) çevirir
            let islenmisFoto = UIImage(data: responseData)
            
            // Sonucu ana ekrana gönderir
            DispatchQueue.main.async {
                completion(islenmisFoto)
            }
        }.resume() // Bu komut olmazsa işlem başlamaz, "ateşle" düğmesidir
    }
}
