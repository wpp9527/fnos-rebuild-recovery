package llnut

func AccountListQuery() string {
    return "SELECT UID, accountname, COALESCE(admin, 0) AS admin, COALESCE(parent_uid, 0) AS parent_uid FROM d_taiwan.accounts ORDER BY UID LIMIT ? OFFSET ?"
}

func CharacterListQuery() string {
    return "SELECT charac_no, charac_name, lev, job, m_id FROM taiwan_cain.charac_info ORDER BY charac_no LIMIT ? OFFSET ?"
}
