package com.soldesk.util;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

@Component
public class FileUploadUtil {

    @Value("${upload.path}")
    private String uploadPath;

    private static final List<String> ALLOWED_IMAGE_EXT = Arrays.asList("jpg", "jpeg", "png", "gif", "webp");
    private static final List<String> ALLOWED_VIDEO_EXT = Arrays.asList("mp4", "webm");

    public static class SavedFileInfo {
        public String origName;
        public String savedName;
        public String filePath;   // /uploads/... URL로 쓸 상대경로
        public String fileType;   // IMAGE / VIDEO
        public long fileSize;
    }

    public SavedFileInfo save(MultipartFile file) throws IOException {
        String origName = file.getOriginalFilename();
        String ext = getExt(origName).toLowerCase();

        String fileType;
        if (ALLOWED_IMAGE_EXT.contains(ext)) {
            fileType = "IMAGE";
        } else if (ALLOWED_VIDEO_EXT.contains(ext)) {
            fileType = "VIDEO";
        } else {
            throw new IllegalArgumentException("허용되지 않는 파일 형식입니다: " + ext);
        }

        // 날짜별 서브폴더
        String dateFolder = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy/MM/dd"));
        Path dirPath = Paths.get(uploadPath, dateFolder);
        Files.createDirectories(dirPath);

        String savedName = UUID.randomUUID().toString() + "." + ext;
        Path targetPath = dirPath.resolve(savedName);
        file.transferTo(targetPath.toFile());

        SavedFileInfo info = new SavedFileInfo();
        info.origName = origName;
        info.savedName = savedName;
        info.filePath = "/uploads/" + dateFolder + "/" + savedName; // JSP에서 그대로 src로 사용 가능
        info.fileType = fileType;
        info.fileSize = file.getSize();
        return info;
    }

    private String getExt(String filename) {
        if (filename == null || !filename.contains(".")) return "";
        return filename.substring(filename.lastIndexOf(".") + 1);
    }

    public void delete(String filePath) {
        try {
            // filePath 예: /uploads/2026/08/21/xxxx.png -> uploadPath 기준 상대경로로 변환
            String relative = filePath.replaceFirst("^/uploads/", "");
            Path target = Paths.get(uploadPath, relative);
            Files.deleteIfExists(target);
        } catch (IOException e) {
            e.printStackTrace();
    }
}
}