package com.soldesk.vo;

import java.time.LocalDateTime;

import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

public class MemberVO {
    private int memberId; // 회원 고유번호

    @NotBlank(message = "이메일을 입력해주세요")
    @Email(message = "이메일 형식이 올바르지 않습니다")
    private String memberEmail; // 로그인 아이디

    @NotBlank(message = "비밀번호를 입력해주세요")
    @Pattern(regexp = "^$|^(?=.*[A-Za-z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,}$", message = "영문, 숫자, 특수문자 조합 8자 이상 입력해주세요")
    private String memberPassword; // 비밀번호(암호화 저장)
    @NotBlank(message = "비밀번호를 다시 입력해주세요")
    private String memberPasswordConfirm; // 비밀번호 확인

    @NotBlank(message = "이름을 입력해주세요")
    @Pattern(regexp = "^$|^[가-힣]{2,10}$", message = "한글 이름만 가입이 가능합니다.") 
    private String memberName; // 이름

    private String memberProfileImage; // 프로필 이미지 URL

    private String role; // 권한 (enum: MemberRole, USER/ADMIN)

    private String status; // 상태 (enum: MemberStatus, ACTIVE/DORMANT/WITHDRAWN)
    private LocalDateTime regDate; // 가입일시

    // oAuth용
    private String provider;
    private String providerId;


    public String getProvider() {
        return provider;
    }
    public void setProvider(String provider) {
        this.provider = provider;
    }
    public String getProviderId() {
        return providerId;
    }
    public void setProviderId(String providerId) {
        this.providerId = providerId;
    }
    public int getMemberId() {
        return memberId;
    }
    public void setMemberId(int memberId) {
        this.memberId = memberId;
    }
    public String getMemberEmail() {
        return memberEmail;
    }
    public void setMemberEmail(String memberEmail) {
        this.memberEmail = memberEmail;
    }
    public String getMemberPassword() {
        return memberPassword;
    }
    public void setMemberPassword(String memberPassword) {
        this.memberPassword = memberPassword;
    }
    public String getMemberPasswordConfirm() {
        return memberPasswordConfirm;
    }
    public void setMemberPasswordConfirm(String memberPasswordComfirm) {
        this.memberPasswordConfirm = memberPasswordComfirm;
    }
    public String getMemberName() {
        return memberName;
    }
    public void setMemberName(String memberName) {
        this.memberName = memberName;
    }
    public String getMemberProfileImage() {
        return memberProfileImage;
    }
    public void setMemberProfileImage(String memberProfileImage) {
        this.memberProfileImage = memberProfileImage;
    }
    public String getRole() {
        return role;
    }
    public void setRole(String role) {
        this.role = role;
    }
    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }
    public LocalDateTime getRegDate() {
        return regDate;
    }
    public void setRegDate(LocalDateTime regDate) {
        this.regDate = regDate;
    }
}
