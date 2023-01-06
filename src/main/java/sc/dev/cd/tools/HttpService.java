package sc.dev.cd.tools;

import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

@Service
public class HttpService {

    public ResponseEntity<byte[]> downloadFile(byte[] bytes, String desiredName) {
        HttpHeaders httpHeaders = new HttpHeaders();
        httpHeaders.set(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_OCTET_STREAM_VALUE); // (3) Content-Type: application/octet-stream
        httpHeaders.set(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(desiredName).build().toString()); // (4) Content-Disposition: attachment; filename="demo-file.txt"
        return ResponseEntity.ok().headers(httpHeaders).body(bytes); // (5) Return Response
    }

    public ResponseEntity<String> getString(String query, String token) throws URISyntaxException, IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder(new URI(query)) //?user_id=gt.2540
                .header("Authorization", "Bearer " + token)
                .GET().build();
        HttpResponse<String> response = HttpClient.newBuilder().build().send(request, HttpResponse.BodyHandlers.ofString());
        return ResponseEntity.ok().body(response.body());
    }
}