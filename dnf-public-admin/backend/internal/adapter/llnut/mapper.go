package llnut

import "strconv"

func AccountFromRow(uid int64, username string, admin int, parentUID int64) Account {
    status := "active"
    if admin > 0 {
        status = "admin"
    }
    return Account{ID: strconv.FormatInt(uid, 10), Username: username, Status: status, Roles: 0}
}

func CharacterFromRow(characNo int64, name string, level int, job int, accountID int64) Character {
    return Character{ID: strconv.FormatInt(characNo, 10), Name: name, Level: level, Job: strconv.Itoa(job), AccountID: strconv.FormatInt(accountID, 10)}
}
