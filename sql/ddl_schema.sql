-- ============================================================
-- 전산팀 문서 중앙관리 시스템 - PostgreSQL DDL 스크립트
-- 작성일: 2024년
-- 테이블: 15개
-- ============================================================

-- 기존 테이블 삭제 (개발 환경용, 운영 시 주석 처리)
DROP TABLE IF EXISTS equipment_credential CASCADE;
DROP TABLE IF EXISTS user_credential CASCADE;
DROP TABLE IF EXISTS consumable_history CASCADE;
DROP TABLE IF EXISTS sw_installation CASCADE;
DROP TABLE IF EXISTS equipment_user CASCADE;
DROP TABLE IF EXISTS ip_allocation CASCADE;
DROP TABLE IF EXISTS wireless_ap CASCADE;
DROP TABLE IF EXISTS network_policy CASCADE;
DROP TABLE IF EXISTS regular_payment CASCADE;
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS it_request CASCADE;
DROP TABLE IF EXISTS printer_consumable CASCADE;
DROP TABLE IF EXISTS software_license CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS equipment CASCADE;

-- ============================================================
-- 1. equipment (장비 마스터)
-- ============================================================
CREATE TABLE equipment (
    equipment_id    SERIAL PRIMARY KEY,
    asset_no        VARCHAR(20) NOT NULL UNIQUE,
    category        VARCHAR(20) NOT NULL,
    sub_category    VARCHAR(30),
    model_name      VARCHAR(100),
    serial_no       VARCHAR(50),
    purchase_date   DATE,
    status          VARCHAR(20) NOT NULL DEFAULT '사용중',
    location        VARCHAR(50),
    department      VARCHAR(50),
    os              VARCHAR(50),
    cpu             VARCHAR(100),
    memory          VARCHAR(30),
    storage         VARCHAR(50),
    note            TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_equipment_category CHECK (category IN ('PC', '노트북', '서버', '프린터', '네트워크', '기타')),
    CONSTRAINT chk_equipment_status CHECK (status IN ('사용중', '미사용', '폐기', '수리중'))
);

CREATE INDEX idx_equipment_category ON equipment(category);
CREATE INDEX idx_equipment_status ON equipment(status);
CREATE INDEX idx_equipment_department ON equipment(department);

COMMENT ON TABLE equipment IS '장비 마스터 - PC, 서버, 프린터, 네트워크 장비 통합 관리';

-- ============================================================
-- 2. users (사용자 마스터)
-- ============================================================
CREATE TABLE users (
    user_id         SERIAL PRIMARY KEY,
    emp_no          VARCHAR(10) NOT NULL UNIQUE,
    name            VARCHAR(50) NOT NULL,
    department      VARCHAR(50),
    position        VARCHAR(30),
    location_type   VARCHAR(10),
    status          VARCHAR(20) NOT NULL DEFAULT '재직',
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_users_location_type CHECK (location_type IN ('사내', '사외')),
    CONSTRAINT chk_users_status CHECK (status IN ('재직', '퇴사', '휴직'))
);

CREATE INDEX idx_users_department ON users(department);
CREATE INDEX idx_users_status ON users(status);

COMMENT ON TABLE users IS '사용자 마스터 - 임직원 정보 관리';

-- ============================================================
-- 3. equipment_user (장비-사용자 매핑)
-- ============================================================
CREATE TABLE equipment_user (
    mapping_id      SERIAL PRIMARY KEY,
    equipment_id    INTEGER NOT NULL,
    user_id         INTEGER NOT NULL,
    assigned_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    returned_date   DATE,
    is_current      BOOLEAN NOT NULL DEFAULT TRUE,
    note            TEXT,
    
    CONSTRAINT fk_eu_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON DELETE CASCADE,
    CONSTRAINT fk_eu_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_eu_equipment_id ON equipment_user(equipment_id);
CREATE INDEX idx_eu_user_id ON equipment_user(user_id);
CREATE INDEX idx_eu_is_current ON equipment_user(is_current);

COMMENT ON TABLE equipment_user IS '장비-사용자 매핑 - 장비 할당 이력 관리';

-- ============================================================
-- 4. ip_allocation (IP 할당 현황)
-- ============================================================
CREATE TABLE ip_allocation (
    ip_id           SERIAL PRIMARY KEY,
    ip_address      VARCHAR(15) NOT NULL UNIQUE,
    mac_address     VARCHAR(17),
    network_zone    VARCHAR(30) NOT NULL,
    allocation_type VARCHAR(10) NOT NULL,
    equipment_id    INTEGER,
    description     VARCHAR(100),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_ip_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON DELETE SET NULL,
    CONSTRAINT chk_ip_network_zone CHECK (network_zone IN ('V10-고정', 'V10-DHCP', 'V40-폐쇄망', 'V50-Guest', '2공장')),
    CONSTRAINT chk_ip_allocation_type CHECK (allocation_type IN ('고정', 'DHCP'))
);

CREATE INDEX idx_ip_network_zone ON ip_allocation(network_zone);
CREATE INDEX idx_ip_equipment_id ON ip_allocation(equipment_id);

COMMENT ON TABLE ip_allocation IS 'IP 할당 현황 - IP 주소 및 MAC 관리';

-- ============================================================
-- 5. software_license (SW 라이선스 마스터)
-- ============================================================
CREATE TABLE software_license (
    license_id      SERIAL PRIMARY KEY,
    sw_name         VARCHAR(100) NOT NULL,
    sw_version      VARCHAR(50),
    license_type    VARCHAR(20),
    license_key     VARCHAR(100),
    total_qty       INTEGER NOT NULL DEFAULT 1,
    purchase_date   DATE,
    expire_date     DATE,
    vendor          VARCHAR(100),
    note            TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_license_type CHECK (license_type IN ('영구', '구독', '볼륨'))
);

CREATE INDEX idx_license_sw_name ON software_license(sw_name);
CREATE INDEX idx_license_sw_version ON software_license(sw_version);

COMMENT ON TABLE software_license IS 'SW 라이선스 마스터 - 소프트웨어 라이선스 보유 현황';

-- ============================================================
-- 6. sw_installation (SW 설치 현황)
-- ============================================================
CREATE TABLE sw_installation (
    install_id      SERIAL PRIMARY KEY,
    equipment_id    INTEGER NOT NULL,
    license_id      INTEGER NOT NULL,
    user_id         INTEGER,
    install_date    DATE,
    uninstall_date  DATE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    note            TEXT,
    
    CONSTRAINT fk_swi_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON DELETE CASCADE,
    CONSTRAINT fk_swi_license FOREIGN KEY (license_id) REFERENCES software_license(license_id) ON DELETE CASCADE,
    CONSTRAINT fk_swi_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE INDEX idx_swi_equipment_id ON sw_installation(equipment_id);
CREATE INDEX idx_swi_license_id ON sw_installation(license_id);
CREATE INDEX idx_swi_is_active ON sw_installation(is_active);

COMMENT ON TABLE sw_installation IS 'SW 설치 현황 - 장비별 소프트웨어 설치 이력';

-- ============================================================
-- 7. printer_consumable (프린터 소모품 마스터)
-- ============================================================
CREATE TABLE printer_consumable (
    consumable_id       SERIAL PRIMARY KEY,
    consumable_code     VARCHAR(30) NOT NULL UNIQUE,
    consumable_name     VARCHAR(100),
    consumable_type     VARCHAR(20) NOT NULL,
    compatible_models   TEXT,
    unit_price          INTEGER,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_consumable_type CHECK (consumable_type IN ('토너', '드럼', '잉크', '기타'))
);

COMMENT ON TABLE printer_consumable IS '프린터 소모품 마스터 - 토너 등 소모품 정보';

-- ============================================================
-- 8. consumable_history (소모품 교체 이력)
-- ============================================================
CREATE TABLE consumable_history (
    history_id      SERIAL PRIMARY KEY,
    equipment_id    INTEGER NOT NULL,
    consumable_id   INTEGER NOT NULL,
    replace_date    DATE NOT NULL,
    quantity        INTEGER NOT NULL DEFAULT 1,
    note            TEXT,
    
    CONSTRAINT fk_ch_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON DELETE CASCADE,
    CONSTRAINT fk_ch_consumable FOREIGN KEY (consumable_id) REFERENCES printer_consumable(consumable_id) ON DELETE CASCADE
);

CREATE INDEX idx_ch_equipment_id ON consumable_history(equipment_id);
CREATE INDEX idx_ch_replace_date ON consumable_history(replace_date);

COMMENT ON TABLE consumable_history IS '소모품 교체 이력 - 프린터 토너 교체 등 이력 관리';

-- ============================================================
-- 9. it_request (전산업무 의뢰)
-- ============================================================
CREATE TABLE it_request (
    request_id      SERIAL PRIMARY KEY,
    request_no      VARCHAR(20) NOT NULL UNIQUE,
    request_type    VARCHAR(20) NOT NULL,
    requester       VARCHAR(50) NOT NULL,
    request_date    DATE NOT NULL,
    complete_date   DATE,
    category        VARCHAR(20),
    title           VARCHAR(200),
    content         TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT '접수',
    handler         VARCHAR(50),
    note            TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_request_type CHECK (request_type IN ('KHERP', 'VNERP', 'ETC')),
    CONSTRAINT chk_request_category CHECK (category IN ('신규개발', '기능개선', '오류수정', '구입', '수리')),
    CONSTRAINT chk_request_status CHECK (status IN ('접수', '진행중', '완료', '보류'))
);

CREATE INDEX idx_request_type ON it_request(request_type);
CREATE INDEX idx_request_status ON it_request(status);
CREATE INDEX idx_request_date ON it_request(request_date);

COMMENT ON TABLE it_request IS '전산업무 의뢰 - IT 업무 요청 및 처리 현황';

-- ============================================================
-- 10. payment (정기지불/품의 관리)
-- ============================================================
CREATE TABLE payment (
    payment_id      SERIAL PRIMARY KEY,
    payment_no      VARCHAR(20),
    payment_date    DATE NOT NULL,
    category        VARCHAR(20) NOT NULL,
    account         VARCHAR(50),
    item_name       VARCHAR(100) NOT NULL,
    specification   VARCHAR(100),
    quantity        INTEGER,
    unit_price      INTEGER,
    amount          INTEGER NOT NULL,
    vendor          VARCHAR(100),
    status          VARCHAR(20),
    note            TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_payment_category CHECK (category IN ('품의', '물품')),
    CONSTRAINT chk_payment_status CHECK (status IN ('OK', '반려', '대기'))
);

CREATE INDEX idx_payment_date ON payment(payment_date);
CREATE INDEX idx_payment_category ON payment(category);
CREATE INDEX idx_payment_account ON payment(account);

COMMENT ON TABLE payment IS '정기지불/품의 관리 - 전산실 비용 지출 관리';

-- ============================================================
-- 11. regular_payment (정기지불 항목)
-- ============================================================
CREATE TABLE regular_payment (
    regular_id      SERIAL PRIMARY KEY,
    vendor          VARCHAR(100) NOT NULL,
    item_name       VARCHAR(100) NOT NULL,
    base_price      INTEGER,
    discount        INTEGER,
    vat             INTEGER,
    total_price     INTEGER NOT NULL,
    billing_type    VARCHAR(30),
    manager         VARCHAR(50),
    note            TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_regular_vendor ON regular_payment(vendor);
CREATE INDEX idx_regular_is_active ON regular_payment(is_active);

COMMENT ON TABLE regular_payment IS '정기지불 항목 - 월 정기 지출 항목 관리';

-- ============================================================
-- 12. network_policy (방화벽 정책)
-- ============================================================
CREATE TABLE network_policy (
    policy_id       SERIAL PRIMARY KEY,
    policy_no       INTEGER,
    direction       VARCHAR(10) NOT NULL,
    source_ip       TEXT,
    source_desc     TEXT,
    dest_public_ip  VARCHAR(50),
    dest_private_ip VARCHAR(50),
    dest_desc       VARCHAR(100),
    service         TEXT,
    action          VARCHAR(10) NOT NULL,
    is_enabled      BOOLEAN NOT NULL DEFAULT TRUE,
    note            TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_policy_action CHECK (action IN ('Allow', 'Deny'))
);

CREATE INDEX idx_policy_no ON network_policy(policy_no);
CREATE INDEX idx_policy_action ON network_policy(action);
CREATE INDEX idx_policy_is_enabled ON network_policy(is_enabled);

COMMENT ON TABLE network_policy IS '방화벽 정책 - 방화벽 정책 관리';

-- ============================================================
-- 13. wireless_ap (무선 AP 현황)
-- ============================================================
CREATE TABLE wireless_ap (
    ap_id           SERIAL PRIMARY KEY,
    asset_no        VARCHAR(20) NOT NULL UNIQUE,
    location        VARCHAR(50) NOT NULL,
    ssid            VARCHAR(50),
    model           VARCHAR(100),
    ip_address      VARCHAR(15),
    support_5g      BOOLEAN,
    support_gigabit BOOLEAN,
    speed_info      VARCHAR(100),
    status          VARCHAR(20) NOT NULL DEFAULT '사용중',
    note            TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_ap_status CHECK (status IN ('사용중', '교체검토', '미사용'))
);

CREATE INDEX idx_ap_location ON wireless_ap(location);
CREATE INDEX idx_ap_status ON wireless_ap(status);

COMMENT ON TABLE wireless_ap IS '무선 AP 현황 - 사내 무선 공유기 관리';

-- ============================================================
-- 14. user_credential (사용자 인증정보) - 보안 분리
-- ============================================================
CREATE TABLE user_credential (
    credential_id   SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL UNIQUE,
    pc_id           VARCHAR(50),
    pc_pw           VARCHAR(100),
    email_id        VARCHAR(100),
    email_pw        VARCHAR(100),
    note            TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_uc_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

COMMENT ON TABLE user_credential IS '사용자 인증정보 - PC 로그인, 메일 등 (보안 분리)';
COMMENT ON COLUMN user_credential.pc_pw IS '암호화 저장 권장';
COMMENT ON COLUMN user_credential.email_pw IS '암호화 저장 권장';

-- ============================================================
-- 15. equipment_credential (장비 인증정보) - 보안 분리
-- ============================================================
CREATE TABLE equipment_credential (
    credential_id   SERIAL PRIMARY KEY,
    equipment_id    INTEGER NOT NULL UNIQUE,
    bios_pw         VARCHAR(100),
    bitlocker_pw    VARCHAR(100),
    kensington_lock VARCHAR(50),
    admin_id        VARCHAR(50),
    admin_pw        VARCHAR(100),
    note            TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_ec_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON DELETE CASCADE
);

COMMENT ON TABLE equipment_credential IS '장비 인증정보 - BIOS, BitLocker, 잠금장치 등 (보안 분리)';
COMMENT ON COLUMN equipment_credential.bios_pw IS '암호화 저장 권장';
COMMENT ON COLUMN equipment_credential.bitlocker_pw IS 'BitLocker 복구키 48자리, 암호화 저장 권장';
COMMENT ON COLUMN equipment_credential.admin_pw IS '서버 관리자 비밀번호, 암호화 저장 권장';

-- ============================================================
-- updated_at 자동 갱신 트리거
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 각 테이블에 트리거 적용
CREATE TRIGGER trg_equipment_updated_at BEFORE UPDATE ON equipment FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_ip_allocation_updated_at BEFORE UPDATE ON ip_allocation FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_software_license_updated_at BEFORE UPDATE ON software_license FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_it_request_updated_at BEFORE UPDATE ON it_request FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_regular_payment_updated_at BEFORE UPDATE ON regular_payment FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_network_policy_updated_at BEFORE UPDATE ON network_policy FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_wireless_ap_updated_at BEFORE UPDATE ON wireless_ap FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_user_credential_updated_at BEFORE UPDATE ON user_credential FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_equipment_credential_updated_at BEFORE UPDATE ON equipment_credential FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 완료 메시지
-- ============================================================
DO $$
BEGIN
    RAISE NOTICE '전산팀 문서 중앙관리 시스템 - 테이블 15개 생성 완료';
END $$;
