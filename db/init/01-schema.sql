SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE `board` (
  `board_id` bigint NOT NULL AUTO_INCREMENT COMMENT '게시글 고유번호',
  `member_id` bigint DEFAULT NULL COMMENT '작성자 회원 번호',
  `board_title` varchar(200) NOT NULL COMMENT '제목',
  `board_content` text NOT NULL COMMENT '내용',
  `category_idx` varchar(30) NOT NULL COMMENT '게시판 유형 (enum: BoardType, NOTICE/FREE/QNA) - 조회 시 이 값으로 필터링',
  `view_count` int NOT NULL DEFAULT '0' COMMENT '조회수',
  `notice_yn` char(1) NOT NULL DEFAULT 'N' COMMENT '공지 여부(Y/N)',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시',
  `mod_date` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',
  PRIMARY KEY (`board_id`),
  KEY `fk_board_member` (`member_id`),
  KEY `idx_board_category` (`category_idx`),
  KEY `idx_board_reg_date` (`reg_date`),
  KEY `idx_board_category_idx` (`category_idx`),
  KEY `idx_board_member_id` (`member_id`),
  CONSTRAINT `fk_board_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='게시글 (board 유형은 category_idx 로 구분, post 테이블 통합)';

CREATE TABLE `board_file` (
  `board_file_id` bigint NOT NULL AUTO_INCREMENT COMMENT '첨부파일 고유번호',
  `board_id` bigint NOT NULL COMMENT '게시글 번호',
  `orig_name` varchar(255) NOT NULL COMMENT '원본 파일명',
  `saved_name` varchar(255) NOT NULL COMMENT 'UUID 기반 저장 파일명 (충돌 방지)',
  `file_path` varchar(500) NOT NULL COMMENT '서버 저장 경로 (예: /uploads/2026/08/19/xxxx.jpg)',
  `file_type` enum('IMAGE','VIDEO') NOT NULL COMMENT '파일 종류',
  `file_size` bigint NOT NULL COMMENT '파일 크기 (byte)',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '업로드 일시',
  PRIMARY KEY (`board_file_id`),
  KEY `fk_board_file_board` (`board_id`),
  CONSTRAINT `fk_board_file_board` FOREIGN KEY (`board_id`) REFERENCES `board` (`board_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='게시글 첨부파일 (이미지/영상)';

CREATE TABLE `chain_room` (
  `chain_room_id` bigint NOT NULL AUTO_INCREMENT COMMENT '게임방 고유번호',
  `chain_room_name` varchar(100) NOT NULL COMMENT '방 이름',
  `status` varchar(30) NOT NULL DEFAULT 'WAITING' COMMENT '방 상태 (enum: RoomStatus, WAITING/PLAYING/ENDED)',
  `chain_room_capacity` int NOT NULL DEFAULT '4' COMMENT '최대 참여 인원',
  `turn_time_limit_base_sec` int NOT NULL DEFAULT '8' COMMENT '턴 기본 제한시간(초). 자모 1개 확정마다 +2초 (서버 로직, DB에는 기본값만 저장)',
  `host_member_id` bigint NOT NULL COMMENT '방장 회원 번호',
  `current_turn_member_id` bigint DEFAULT NULL COMMENT '현재 턴 회원 번호',
  `current_turn_deadline` datetime DEFAULT NULL COMMENT '현재 턴 마감 시각 (서버 권위 타임아웃 판정 기준)',
  `last_chain_word_id` bigint DEFAULT NULL COMMENT '마지막으로 성공 처리된 단어 번호',
  `winner_member_id` bigint DEFAULT NULL COMMENT '우승 회원 번호',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '방 생성일시',
  `started_date` datetime DEFAULT NULL COMMENT '게임 시작일시',
  `ended_date` datetime DEFAULT NULL COMMENT '게임 종료일시',
  PRIMARY KEY (`chain_room_id`),
  KEY `fk_chain_room_host` (`host_member_id`),
  KEY `fk_chain_room_turn_member` (`current_turn_member_id`),
  KEY `fk_chain_room_last_word` (`last_chain_word_id`),
  KEY `fk_chain_room_winner` (`winner_member_id`),
  CONSTRAINT `fk_chain_room_host` FOREIGN KEY (`host_member_id`) REFERENCES `member` (`member_id`),
  CONSTRAINT `fk_chain_room_last_word` FOREIGN KEY (`last_chain_word_id`) REFERENCES `chain_word` (`chain_word_id`),
  CONSTRAINT `fk_chain_room_turn_member` FOREIGN KEY (`current_turn_member_id`) REFERENCES `member` (`member_id`),
  CONSTRAINT `fk_chain_room_winner` FOREIGN KEY (`winner_member_id`) REFERENCES `member` (`member_id`),
  CONSTRAINT `chk_chain_room_capacity` CHECK ((`chain_room_capacity` between 2 and 6))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='끝말잇기 게임방';

CREATE TABLE `chain_room_member` (
  `chain_room_id` bigint NOT NULL COMMENT '게임방 번호',
  `member_id` bigint NOT NULL COMMENT '참여 회원 번호',
  `turn_no` int NOT NULL COMMENT '턴 순서',
  `joined_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '입장일시',
  `left_date` datetime DEFAULT NULL COMMENT '퇴장일시',
  `lives` int NOT NULL DEFAULT '3' COMMENT '남은 목숨',
  `score` int NOT NULL DEFAULT '0' COMMENT '누적 점수',
  `eliminated_yn` char(1) NOT NULL DEFAULT 'N' COMMENT '탈락 여부(Y/N)',
  `final_rank` int DEFAULT NULL COMMENT '최종 순위 (게임 종료 시 확정, 1=우승)',
  `eliminated_date` datetime DEFAULT NULL COMMENT '탈락 확정 일시',
  PRIMARY KEY (`chain_room_id`,`member_id`),
  KEY `fk_chain_room_member_member` (`member_id`),
  KEY `idx_chain_room_member_member` (`member_id`),
  CONSTRAINT `fk_chain_room_member_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`),
  CONSTRAINT `fk_chain_room_member_room` FOREIGN KEY (`chain_room_id`) REFERENCES `chain_room` (`chain_room_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='끝말잇기 게임방 참여자';

CREATE TABLE `chain_word` (
  `chain_word_id` bigint NOT NULL AUTO_INCREMENT COMMENT '끝말잇기 단어 고유번호',
  `word_name` varchar(100) NOT NULL COMMENT '단어명',
  `first_char` varchar(5) NOT NULL COMMENT '단어 첫 글자',
  `last_char` varchar(5) NOT NULL COMMENT '단어 마지막 글자',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시',
  PRIMARY KEY (`chain_word_id`),
  UNIQUE KEY `uk_chain_word_name` (`word_name`),
  KEY `idx_chain_word_first_char` (`first_char`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='끝말잇기 검증 단어집 (수어사전 sign_word 와 별개)';

CREATE TABLE `chain_word_log` (
  `chain_word_log_id` bigint NOT NULL AUTO_INCREMENT COMMENT '단어 시도 기록 고유번호',
  `chain_room_id` bigint NOT NULL COMMENT '게임방 번호',
  `member_id` bigint NOT NULL COMMENT '시도한 회원 번호',
  `chain_word_id` bigint DEFAULT NULL COMMENT '유효 단어인 경우 매칭된 단어 번호',
  `attempted_word` varchar(100) NOT NULL COMMENT '시도한 단어 원문',
  `turn_no` int NOT NULL COMMENT '턴 번호',
  `is_valid` char(1) NOT NULL COMMENT '유효 여부(Y/N)',
  `invalid_reason_code` varchar(30) DEFAULT NULL COMMENT '무효 사유 (enum: InvalidReason, WRONG_START_CHAR/DUPLICATE/NOT_FOUND)',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '시도일시',
  PRIMARY KEY (`chain_word_log_id`),
  KEY `fk_chain_log_member` (`member_id`),
  KEY `fk_chain_log_word` (`chain_word_id`),
  KEY `idx_chain_log_room` (`chain_room_id`),
  CONSTRAINT `fk_chain_log_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`),
  CONSTRAINT `fk_chain_log_room` FOREIGN KEY (`chain_room_id`) REFERENCES `chain_room` (`chain_room_id`),
  CONSTRAINT `fk_chain_log_word` FOREIGN KEY (`chain_word_id`) REFERENCES `chain_word` (`chain_word_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='끝말잇기 단어 시도 기록';

CREATE TABLE `comment` (
  `comment_id` bigint NOT NULL AUTO_INCREMENT COMMENT '댓글 고유번호',
  `comment_content` text NOT NULL COMMENT '댓글 내용',
  `del_yn` char(1) NOT NULL DEFAULT 'N',
  `board_id` bigint NOT NULL COMMENT '게시글 번호',
  `member_id` bigint DEFAULT NULL COMMENT '작성자 회원 번호',
  `parent_comment_id` bigint DEFAULT NULL COMMENT '부모 댓글 번호 (대댓글용)',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시',
  `is_admin_answer` char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`comment_id`),
  KEY `fk_comment_member` (`member_id`),
  KEY `fk_comment_parent` (`parent_comment_id`),
  KEY `idx_comment_board` (`board_id`),
  KEY `idx_comment_board_id_del_yn` (`board_id`,`del_yn`),
  KEY `idx_comment_member_id` (`member_id`),
  KEY `idx_comment_parent_comment_id` (`parent_comment_id`),
  CONSTRAINT `fk_comment_board` FOREIGN KEY (`board_id`) REFERENCES `board` (`board_id`),
  CONSTRAINT `fk_comment_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`),
  CONSTRAINT `fk_comment_parent` FOREIGN KEY (`parent_comment_id`) REFERENCES `comment` (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='댓글';

CREATE TABLE `inquiry` (
  `inquiry_id` bigint NOT NULL AUTO_INCREMENT COMMENT '문의 고유번호',
  `member_id` bigint NOT NULL COMMENT '문의 등록 회원 번호',
  `category` varchar(30) NOT NULL COMMENT '문의 유형 (enum: InquiryCategory, ACTION_RECOGNITION/VIDEO_PLAYBACK/TRANSLATION/UI_BUG/ETC)',
  `title` varchar(200) NOT NULL COMMENT '제목',
  `content` text NOT NULL COMMENT '문의 내용',
  `status` varchar(30) NOT NULL DEFAULT 'WAIT' COMMENT '처리 상태 (enum: InquiryStatus, WAIT/PROCESSING/COMPLETE)',
  `answer_content` text COMMENT '답변 내용',
  `answered_member_id` bigint DEFAULT NULL COMMENT '답변한 관리자 회원 번호',
  `answered_date` datetime DEFAULT NULL COMMENT '답변일시',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시',
  `mod_date` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',
  `board_id` int DEFAULT NULL,
  PRIMARY KEY (`inquiry_id`),
  KEY `fk_inquiry_member` (`member_id`),
  KEY `fk_inquiry_answered_member` (`answered_member_id`),
  KEY `idx_inquiry_status` (`status`),
  CONSTRAINT `fk_inquiry_answered_member` FOREIGN KEY (`answered_member_id`) REFERENCES `member` (`member_id`),
  CONSTRAINT `fk_inquiry_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='고객센터 문의 / 오류제보';

CREATE TABLE `jamo` (
  `jamo_id` bigint NOT NULL AUTO_INCREMENT COMMENT '자모 고유번호',
  `jamo_char` varchar(5) NOT NULL COMMENT '자모 문자 (예: ㄱ, ㅏ)',
  `jamo_type` varchar(30) NOT NULL COMMENT '자모 구분 (enum: JamoType, CONSONANT/VOWEL)',
  `jamo_name` varchar(50) NOT NULL COMMENT '자모 명칭 (예: 기역, 아)',
  `jamo_info` text COMMENT '손모양 설명',
  `jamo_image` varchar(500) DEFAULT NULL COMMENT '손모양 이미지 URL',
  PRIMARY KEY (`jamo_id`),
  UNIQUE KEY `uk_jamo_char` (`jamo_char`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='지문자(자음/모음) 학습 정보';

CREATE TABLE `member` (
  `member_id` bigint NOT NULL AUTO_INCREMENT COMMENT '회원 고유번호',
  `member_email` varchar(50) NOT NULL COMMENT '로그인 아이디',
  `member_password` varchar(255) NOT NULL COMMENT '비밀번호(암호화 저장)',
  `member_name` varchar(50) NOT NULL COMMENT '이름',
  `member_profile_image` varchar(500) DEFAULT NULL COMMENT '프로필 이미지 URL',
  `role` varchar(30) NOT NULL DEFAULT 'USER' COMMENT '권한 (enum: MemberRole, USER/ADMIN)',
  `status` varchar(30) NOT NULL DEFAULT 'ACTIVE' COMMENT '상태 (enum: MemberStatus, ACTIVE/DORMANT/WITHDRAWN)',
  `point` int NOT NULL DEFAULT '0' COMMENT '누적 점수 (끝말잇기 등에서 획득)',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '가입일시',
  `provider` varchar(20) DEFAULT 'LOCAL',
  `provider_id` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`member_id`),
  UNIQUE KEY `uk_member_member_email` (`member_email`),
  UNIQUE KEY `uq_member_email` (`member_email`),
  UNIQUE KEY `uq_member_provider` (`provider`,`provider_id`),
  KEY `idx_member_reg_date` (`reg_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='회원';

CREATE TABLE `member_favorite_word` (
  `member_id` bigint NOT NULL,
  `sign_word_id` bigint NOT NULL,
  `reg_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`member_id`,`sign_word_id`),
  KEY `fk_fav_word` (`sign_word_id`),
  CONSTRAINT `fk_fav_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_fav_word` FOREIGN KEY (`sign_word_id`) REFERENCES `sign_word` (`sign_word_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `member_setting` (
  `member_id` bigint NOT NULL,
  `setting_key` varchar(50) NOT NULL,
  `setting_value` varchar(100) NOT NULL,
  PRIMARY KEY (`member_id`,`setting_key`),
  CONSTRAINT `fk_setting_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `member_suspension` (
  `suspension_id` bigint NOT NULL AUTO_INCREMENT COMMENT '정지 이력 고유번호',
  `member_id` bigint NOT NULL COMMENT '대상 회원',
  `admin_id` bigint NOT NULL COMMENT '정지 처리한 관리자',
  `reason` varchar(500) DEFAULT NULL COMMENT '정지 사유',
  `start_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '정지 시작일시',
  `end_date` datetime DEFAULT NULL COMMENT '정지 종료일시 (NULL=영구정지)',
  PRIMARY KEY (`suspension_id`),
  KEY `fk_suspension_member` (`member_id`),
  KEY `fk_suspension_admin` (`admin_id`),
  CONSTRAINT `fk_suspension_admin` FOREIGN KEY (`admin_id`) REFERENCES `member` (`member_id`),
  CONSTRAINT `fk_suspension_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='회원 정지 이력';

CREATE TABLE `notification` (
  `notification_id` bigint NOT NULL AUTO_INCREMENT COMMENT '알림 고유번호',
  `member_id` bigint NOT NULL COMMENT '수신 회원 번호',
  `notification_type` varchar(30) NOT NULL COMMENT '알림 유형 (enum: NotificationType, COMMENT/ANSWER/GAME_TURN/SYSTEM)',
  `title` varchar(200) NOT NULL COMMENT '알림 제목',
  `content` text COMMENT '알림 내용',
  `link_url` varchar(500) DEFAULT NULL COMMENT '클릭 시 이동 URL',
  `is_read` char(1) NOT NULL DEFAULT 'N' COMMENT '읽음 여부(Y/N)',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시',
  `read_date` datetime DEFAULT NULL COMMENT '읽음 처리 일시',
  PRIMARY KEY (`notification_id`),
  KEY `idx_notification_member_read` (`member_id`,`is_read`),
  CONSTRAINT `fk_notification_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='알림';

CREATE TABLE `recognition_confirm_log` (
  `recognition_confirm_log_id` bigint NOT NULL AUTO_INCREMENT COMMENT '확정 인식 로그 고유번호',
  `client_session_id` varchar(50) NOT NULL COMMENT '클라이언트 세션 ID (웹 로컬스토리지 기반 session id)',
  `member_id` bigint DEFAULT NULL COMMENT '회원 번호 (비로그인 학습 시 NULL)',
  `jamo_id` bigint DEFAULT NULL COMMENT '확정된 자모 번호',
  `confirmed_char` varchar(5) NOT NULL COMMENT '확정 문자',
  `confidence` decimal(5,4) NOT NULL COMMENT '확정 시점 확신도 (0~1)',
  `hold_duration_ms` int NOT NULL COMMENT '유지 시간(ms)',
  `landmark_json` json DEFAULT NULL COMMENT '확정 시점 랜드마크 21개 좌표 (MediaPipe 원본, [{x,y,z}, ...])',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '확정일시',
  PRIMARY KEY (`recognition_confirm_log_id`),
  KEY `fk_confirm_log_member` (`member_id`),
  KEY `fk_confirm_log_jamo` (`jamo_id`),
  KEY `idx_confirm_log_session` (`client_session_id`),
  CONSTRAINT `fk_confirm_log_jamo` FOREIGN KEY (`jamo_id`) REFERENCES `jamo` (`jamo_id`),
  CONSTRAINT `fk_confirm_log_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='자모 확정(입력완료) 로그 - 저빈도, 실시간 동기 기록';

CREATE TABLE `recognition_raw_log` (
  `recognition_raw_log_id` bigint NOT NULL AUTO_INCREMENT COMMENT '원시 예측 로그 고유번호',
  `client_session_id` varchar(50) NOT NULL COMMENT '클라이언트 세션 ID',
  `top1_jamo_char` varchar(5) NOT NULL COMMENT '1순위 예측 문자',
  `top1_confidence` decimal(5,4) NOT NULL COMMENT '1순위 확신도',
  `top2_jamo_char` varchar(5) DEFAULT NULL COMMENT '2순위 예측 문자',
  `top2_confidence` decimal(5,4) DEFAULT NULL COMMENT '2순위 확신도',
  `top3_jamo_char` varchar(5) DEFAULT NULL COMMENT '3순위 예측 문자',
  `top3_confidence` decimal(5,4) DEFAULT NULL COMMENT '3순위 확신도',
  `hold_progress` decimal(4,3) NOT NULL COMMENT 'hold 진행률 (0~1)',
  `is_confirmed` char(1) NOT NULL DEFAULT 'N' COMMENT '이 호출로 확정이 발생했는지 여부(Y/N)',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '요청일시',
  PRIMARY KEY (`recognition_raw_log_id`,`reg_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='0.15초 주기 원시 예측 로그 (샘플링/비동기 배치 삽입 대상, 일 단위 파티셔닝)'
/*!50100 PARTITION BY RANGE (to_days(`reg_date`))
(PARTITION p20260708 VALUES LESS THAN (740171) ENGINE = InnoDB,
 PARTITION p20260709 VALUES LESS THAN (740172) ENGINE = InnoDB,
 PARTITION p_future VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

CREATE TABLE `sign_word` (
  `sign_word_id` bigint NOT NULL AUTO_INCREMENT COMMENT '수어단어 고유번호',
  `sign_word_name` varchar(100) NOT NULL COMMENT '단어명',
  `choseong` varchar(5) DEFAULT NULL COMMENT '단어 첫 글자 초성 (ㄱ~ㅎ), 필터용',
  `sign_word_video` varchar(500) DEFAULT NULL COMMENT '수어 동영상 URL (한국수어사전 API 원본)',
  `sign_word_thumbnail` varchar(500) DEFAULT NULL COMMENT '썸네일 이미지 URL',
  `description` text COMMENT '수형 설명 (API signDescription)',
  `meaning` text,
  `sign_word_api_id` varchar(50) DEFAULT NULL COMMENT '한국수어사전 API 원본 단어 ID (API 재조회용)',
  `view_count` int NOT NULL DEFAULT '0' COMMENT '검색 조회수',
  `reg_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시',
  `mod_date` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',
  PRIMARY KEY (`sign_word_id`),
  UNIQUE KEY `uk_sign_word_name` (`sign_word_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='수어사전 단어 (기반데이터 수백건 + 검색 시 API로 확보되는 단어)';

CREATE TABLE `test_session` (
  `test_session_id` bigint NOT NULL AUTO_INCREMENT COMMENT '테스트 세션 고유번호',
  `member_id` bigint NOT NULL COMMENT '응시 회원 번호',
  `test_session_type` varchar(30) NOT NULL COMMENT '테스트 유형 (enum: TestType, CONSONANT/VOWEL/WORD)',
  `num_of_question` int NOT NULL DEFAULT '0' COMMENT '총 문항 수',
  `correct_count` int NOT NULL DEFAULT '0' COMMENT '정답 수',
  `score` int NOT NULL DEFAULT '0' COMMENT '점수',
  `started_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '시작일시',
  `ended_date` datetime DEFAULT NULL COMMENT '종료일시',
  PRIMARY KEY (`test_session_id`),
  KEY `idx_test_session_member` (`member_id`),
  CONSTRAINT `fk_test_session_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='수어 테스트 응시 세션';

CREATE TABLE `test_session_detail` (
  `test_session_detail_id` bigint NOT NULL AUTO_INCREMENT COMMENT '테스트 문항 결과 고유번호',
  `test_session_id` bigint NOT NULL COMMENT '테스트 세션 번호',
  `sign_word_id` bigint NOT NULL COMMENT '출제된 수어단어 번호',
  `question_no` int NOT NULL COMMENT '문항 순번',
  `user_answer` varchar(100) DEFAULT NULL COMMENT '사용자 응답(인식/입력 결과)',
  `is_correct` char(1) NOT NULL COMMENT '정답 여부(Y/N)',
  `answer_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '응답일시',
  PRIMARY KEY (`test_session_detail_id`),
  KEY `fk_test_detail_word` (`sign_word_id`),
  KEY `idx_test_detail_session` (`test_session_id`),
  CONSTRAINT `fk_test_detail_session` FOREIGN KEY (`test_session_id`) REFERENCES `test_session` (`test_session_id`),
  CONSTRAINT `fk_test_detail_word` FOREIGN KEY (`sign_word_id`) REFERENCES `sign_word` (`sign_word_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='수어 테스트 문항별 응답 결과';

CREATE TABLE `word_exam` (
  `exam_id` char(36) NOT NULL,
  `member_id` int NOT NULL,
  `payload` longtext NOT NULL,
  `started_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`exam_id`),
  KEY `ix_word_exam_member` (`member_id`,`started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SET FOREIGN_KEY_CHECKS = 1;
