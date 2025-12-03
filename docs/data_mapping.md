# 전산팀 IT 자산관리 시스템 - Excel → DB 데이터 매핑 정의서

## 개요

- **프로젝트명**: 전산팀 IT 자산관리 시스템
- **작성일**: 2025년 12월
- **목적**: Excel 원본 데이터를 PostgreSQL 테이블로 초기 이관하기 위한 매핑 규칙 정의
- **용도**: 1회성 초기 데이터 마이그레이션 (이후 웹 시스템에서 직접 관리)
- **원본 파일**: 5개 Excel 파일

---

## 1. 02IP-MAC관리.xlsx → equipment (장비 마스터)

### 1-1. V10-DHCP 시트 (노트북/PC)

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 관리번호 | asset_no | 그대로 |
| - | category | 고정값: '노트북' 또는 '구분자' 기반 판단 |
| 모델명 | model_name | 그대로 |
| S/N | serial_no | 그대로 |
| 구매년월 | purchase_date | 'YYYY.MM' → DATE 변환 |
| - | status | 기본값: '사용중' |
| - | location | IP 대역 기반 추정 |
| - | department | 사용자 부서 참조 |
| OS | os | 그대로 |
| CPU | cpu | 그대로 |
| 메모리 | memory | 그대로 |
| 용량 | storage | 그대로 |
| 비고 | note | 그대로 |

### 1-2. V10-고정대역 시트 (서버/네트워크 장비)

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 관리번호 | asset_no | 그대로 |
| 구분자 | category | 'Switch' → '네트워크', 'SVR' → '서버' 등 |
| 구분자 | sub_category | L2/L3/방화벽 등 추출 |
| 모델명 | model_name | 그대로 |
| S/N | serial_no | 그대로 |
| 구매년월 | purchase_date | 'YYYY.MM' → DATE 변환 |

### 1-3. 서버 및 장비 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| - | asset_no | 명칭 기반 생성 필요 |
| 종류 | category | 'SVR' → '서버' |
| 장비명 | model_name | 그대로 |
| 구매일 | purchase_date | 'YYYY.MM' → DATE 변환 |
| 부서 | department | 그대로 |
| (OS 컬럼) | os | 그대로 |
| (CPU 컬럼) | cpu | 그대로 |
| (메모리-하드 컬럼) | memory, storage | 분리 필요 |

---

## 2. 02IP-MAC관리.xlsx → users (사용자 마스터)

### 2-1. V10-DHCP / V10-고정대역 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| - | emp_no | 03소프트웨어현황에서 매칭 |
| 사용자 | name | 그대로 |
| - | department | 03소프트웨어현황에서 매칭 |
| - | position | 03소프트웨어현황에서 매칭 |
| - | location_type | 기본값: '사내' |
| - | status | 기본값: '재직' |

**참고**: 사용자 정보는 03소프트웨어현황.xlsx의 '종합' 시트가 더 완전함

---

## 3. 03소프트웨어현황.xlsx → users (사용자 마스터 - 주요 원본)

### 3-1. 종합 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 사번 | emp_no | 숫자 → 문자열 (앞자리 0 채움) |
| 성명 | name | 그대로 |
| 부서 | department | 그대로 |
| 직책 | position | 그대로 |
| 위치 | location_type | '사내'/'사외' 그대로 |
| - | status | 기본값: '재직' |

---

## 4. 02IP-MAC관리.xlsx → user_credential (사용자 인증정보)

### 4-1. V10-DHCP / V10-고정대역 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| - | user_id | users 테이블 FK (이름 매칭) |
| PC ID | pc_id | 그대로 |
| PC PW | pc_pw | 그대로 (암호화 저장) |
| 메일 ID | email_id | 그대로 |
| 메일 PW | email_pw | 그대로 (암호화 저장) |

---

## 5. 02IP-MAC관리.xlsx → equipment_credential (장비 인증정보)

### 5-1. 허용불가MAC / 사용자기기관리 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| - | equipment_id | equipment 테이블 FK (관리번호 매칭) |
| BIOS PW | bios_pw | 그대로 (암호화 저장) |
| BITLOCKER PW | bitlocker_pw | 그대로 (암호화 저장) |
| Kensington Lock | kensington_lock | 그대로 |

### 5-2. 서버 및 장비 시트 (서버용)

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 로그인 (ID) | admin_id | 그대로 |
| 로그인 (PW) | admin_pw | 그대로 (암호화 저장) |

---

## 6. 02IP-MAC관리.xlsx → ip_allocation (IP 할당 현황)

### 6-1. V10-DHCP 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| IP | ip_address | 그대로 |
| MAC(유선) | mac_address | 그대로 |
| - | network_zone | 고정값: 'V10-DHCP' |
| - | allocation_type | 고정값: 'DHCP' |
| - | equipment_id | 관리번호로 equipment FK 매칭 |
| 사용자 | description | 그대로 |
| - | is_active | 기본값: TRUE |

### 6-2. V10-고정대역 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| IP | ip_address | 그대로 |
| MAC(유선) | mac_address | 그대로 |
| - | network_zone | 고정값: 'V10-고정' |
| - | allocation_type | 고정값: '고정' |
| 사용자 | description | 그대로 |

### 6-3. V40-폐쇄망 / V50-DHCP / 2공장 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| IP | ip_address | 그대로 |
| - | network_zone | 시트명에 따라: 'V40-폐쇄망', 'V50-Guest', '2공장' |

---

## 7. 03소프트웨어현황.xlsx → software_license (SW 라이선스)

### 7-1. 라이선스LIST 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 소프트웨어-버전 | sw_name, sw_version | 분리 필요 (예: "Office 2016" → sw_name: Office, sw_version: 2016) |
| - | license_type | '영구' 기본, 구독형은 별도 표시 |
| Copy | total_qty | 정수 변환 |
| 비고 | note | 그대로 |

### 7-2. SW관리대장 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 프로그램명 | sw_name | 그대로 |
| 일련번호 | license_key | 그대로 |
| 구입년도 | purchase_date | 'YYYY.MM.DD' → DATE |
| 비고 | note | 그대로 |

---

## 8. 03소프트웨어현황.xlsx → sw_installation (SW 설치 현황)

### 8-1. 종합 시트 (Office, 한글, PDF편집 등 컬럼)

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| - | equipment_id | 사용자 → 장비 매핑 필요 |
| - | license_id | SW명으로 software_license FK 매칭 |
| 사번 | user_id | users FK 매칭 |
| - | install_date | NULL (정보 없음) |
| - | is_active | TRUE |

**변환 로직**: 각 SW 컬럼(Office, 한글, PDF편집 등)이 비어있지 않으면 해당 SW 설치로 기록

---

## 9. 01프린트관리대장.xlsx → equipment (프린터)

### 9-1. 관리대장 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 관리번호 | asset_no | 그대로 |
| - | category | 고정값: '프린터' |
| 제품명 | model_name | 그대로 |
| - | status | '사용중' 기본, 시트명에 '미사용' 포함 시 '미사용' |
| 구분 (층) | location | '3F' → '3층' 등 변환 |
| 설치부서 | department | 그대로 |

---

## 10. 01프린트관리대장.xlsx → printer_consumable (소모품 마스터)

### 10-1. 관리대장 시트 - 토너 컬럼

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 토너 | consumable_code | 그대로 (예: MLT-D403L) |
| - | consumable_name | 코드와 동일 또는 NULL |
| - | consumable_type | 고정값: '토너' |
| 제품명 | compatible_models | 해당 프린터 모델 |

---

## 11. 01프린트관리대장.xlsx → consumable_history (소모품 교체 이력)

### 11-1. 관리대장 시트 - 월별 컬럼

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| - | equipment_id | 관리번호로 equipment FK 매칭 |
| - | consumable_id | 토너 코드로 printer_consumable FK 매칭 |
| 연도+월 컬럼값 | replace_date | '25일' → 해당 연월 + 25일로 DATE 생성 |
| - | quantity | 기본값: 1 (날짜가 여러 개면 개수만큼) |

**변환 로직**: 
- 컬럼 헤더에서 연도(2018년~2025년), 월(1월~12월) 추출
- 셀 값에서 일자 추출 (예: "25일", "4일, 22일")
- 여러 날짜가 있으면 각각 별도 레코드로 생성

---

## 12. 06전산업무의뢰서접수.xlsx → it_request (전산업무 의뢰)

### 12-1. KHERP / VNERP / ETC 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 접수번호 | request_no | 그대로 |
| - | request_type | 시트명: 'KHERP', 'VNERP', 'ETC' |
| 의뢰자 | requester | 그대로 |
| 의뢰일자 | request_date | DATE 변환 |
| 완료일자 | complete_date | DATE 변환 (NULL 허용) |
| 구분 (신규개발~기타) | category | 'O' 표시된 컬럼명 |
| 의뢰내용 | title, content | 짧으면 title, 길면 content |
| - | status | complete_date 있으면 '완료', 없으면 '진행중' |
| 조치내용 | note | 그대로 |

---

## 13. 05전산실정기지불자료.xlsx → payment (품의/지출)

### 13-1. 상세내용 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| - | payment_no | NULL (별도 관리) |
| 일자 | payment_date | DATE 변환 |
| 대분류 | category | '품의', '물품' 그대로 |
| 계정과목 | account | 그대로 |
| 규격 | item_name | 그대로 |
| - | specification | NULL |
| 수량 | quantity | 정수 변환 |
| 단가 | unit_price | 정수 변환 |
| 금액 | amount | 정수 변환 |
| - | vendor | NULL |
| - | status | 기본값: 'OK' |
| 비고 | note | 그대로 |

---

## 14. 05전산실정기지불자료.xlsx → regular_payment (정기지불)

### 14-1. 정기지불리스트 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 업체 | vendor | 그대로 |
| 항목 | item_name | 그대로 |
| 이용료 | base_price | 정수 변환 |
| 할인금액 | discount | 정수 변환 |
| 부가세 | vat | 정수 변환 |
| 지불금액 | total_price | 정수 변환 |
| 청구 | billing_type | 그대로 |
| 담당자 | manager | 그대로 |
| 비고 | note | 그대로 |
| - | is_active | 기본값: TRUE |

---

## 15. 02IP-MAC관리.xlsx → network_policy (방화벽 정책)

### 15-1. 방화벽정책 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 구분 (번호) | policy_no | 정수 변환 |
| 외부/내부 | direction | 'WAN→LAN' 형태로 조합 |
| 출발지 IP | source_ip | 그대로 |
| 출발지IP설명 | source_desc | 그대로 |
| 목적지 공인 IP | dest_public_ip | 그대로 |
| 목적지 사설 IP | dest_private_ip | 그대로 |
| 목적지IP설명 | dest_desc | 그대로 |
| 오픈서비스 | service | 그대로 |
| 허용 차단 | action | 'Allow', 'Deny' |
| - | is_enabled | 기본값: TRUE |

---

## 16. 02IP-MAC관리.xlsx → wireless_ap (무선 AP)

### 16-1. 무선LIST 시트

| 원본 컬럼 | DB 컬럼 | 변환 규칙 |
|----------|---------|----------|
| 비고 (KHE-WF-xxx) | asset_no | 그대로 |
| 설치장소 | location | 그대로 |
| 공유기명 | ssid | 그대로 |
| 모델 | model | 그대로 |
| IP | ip_address | 그대로 |
| Gbps 지원 | support_gigabit | 'O' → TRUE, NULL → FALSE |
| 5G 지원 | support_5g | 'O' → TRUE, NULL → FALSE |
| 상세속도 | speed_info | 그대로 |
| 교체검토 | status | 값 있으면 '교체검토', 없으면 '사용중' |

---

## 데이터 변환 공통 규칙

### 날짜 변환
| 원본 형식 | 변환 방법 |
|----------|----------|
| YYYY.MM | YYYY-MM-01 |
| YYYY.MM.DD | YYYY-MM-DD |
| YYYY-MM-DD 00:00:00 | YYYY-MM-DD |
| XX일 | 연도+월 컬럼 헤더와 조합 |

### NULL 처리
- 빈 셀, 'NaN', '-' → NULL
- 공백만 있는 셀 → NULL

### 중복 처리
- 사용자: 이름 + 부서로 중복 판단
- 장비: 관리번호(asset_no)로 중복 판단
- IP: ip_address로 중복 판단

---

## 진행 현황

### 완료된 작업 (Phase 1)
- [x] 매핑 정의서 작성 (이 문서)
- [x] Python 파싱 모듈 개발
- [x] 테스트 데이터 변환 및 검증

### 다음 단계 (Phase 2)
- [ ] PostgreSQL DB 구축
- [ ] 초기 데이터 이관 실행 (1회성)
- [ ] 데이터 정합성 검증
- [ ] FastAPI 백엔드 CRUD API 개발

### 참고 사항
- 이 매핑 정의서는 초기 데이터 이관(마이그레이션)용입니다.
- 이관 완료 후에는 웹 시스템에서 직접 데이터를 등록/수정/삭제합니다.
- Excel 파일은 더 이상 사용하지 않습니다.
