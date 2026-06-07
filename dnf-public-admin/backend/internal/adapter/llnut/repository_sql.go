package llnut

func (r Repository) ListAccountsPage(limit, offset int) ([]Account, error) {
    if r.mode == ModeDemo {
        return r.demo.ListAccounts(), nil
    }
    if r.db == nil {
        return nil, errLiveDBRequired()
    }
    limit, offset = NormalizeLimitOffset(limit, offset)
    rows, err := r.db.Query(AccountListQuery(), limit, offset)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    accounts := []Account{}
    for rows.Next() {
        var uid int64
        var username string
        var admin int
        var parentUID int64
        if err := rows.Scan(&uid, &username, &admin, &parentUID); err != nil {
            return nil, err
        }
        accounts = append(accounts, AccountFromRow(uid, username, admin, parentUID))
    }
    if err := rows.Err(); err != nil {
        return nil, err
    }
    return accounts, nil
}

func (r Repository) ListCharactersPage(limit, offset int) ([]Character, error) {
    if r.mode == ModeDemo {
        return r.demo.ListCharacters(), nil
    }
    if r.db == nil {
        return nil, errLiveDBRequired()
    }
    limit, offset = NormalizeLimitOffset(limit, offset)
    rows, err := r.db.Query(CharacterListQuery(), limit, offset)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    characters := []Character{}
    for rows.Next() {
        var id int64
        var name string
        var level int
        var job int
        var accountID int64
        if err := rows.Scan(&id, &name, &level, &job, &accountID); err != nil {
            return nil, err
        }
        characters = append(characters, CharacterFromRow(id, name, level, job, accountID))
    }
    if err := rows.Err(); err != nil {
        return nil, err
    }
    return characters, nil
}
