// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 S3rri-dev y colaboradores.
import Foundation
import CSQLite

typealias Row = [String: Any]
func problem(_ text: String) -> NSError { NSError(domain: "Finanzas", code: 1, userInfo: [NSLocalizedDescriptionKey: text]) }
func str(_ r: Row, _ key: String) -> String { r[key] as? String ?? "" }
func num(_ r: Row, _ key: String) -> Int64 { (r[key] as? NSNumber)?.int64Value ?? 0 }
func json(_ value: Any) throws -> String { String(data: try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .fragmentsAllowed]), encoding: .utf8)! }
enum Dates {
    static func day(_ date: Date = Date()) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(identifier: "Europe/Madrid"); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }
    static func valid(_ value: String) -> Bool {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(identifier: "Europe/Madrid"); f.dateFormat = "yyyy-MM-dd"; f.isLenient = false
        guard value.count == 10, let d = f.date(from: value) else { return false }; return day(d) == value
    }
}

final class Database {
    var handle: OpaquePointer?
    init(_ path: String, readonly: Bool = false) throws {
        let flags = (readonly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE) | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK else { let e = problem("No se pudo abrir la base de datos."); sqlite3_close(handle); throw e }
        sqlite3_busy_timeout(handle, 3000)
        try exec("PRAGMA foreign_keys=ON")
        if !readonly { try exec("PRAGMA journal_mode=WAL"); try exec("PRAGMA synchronous=FULL") }
    }
    deinit { sqlite3_close(handle) }
    func exec(_ sql: String, _ args: [Any] = []) throws { _ = try rows(sql, args) }
    func rows(_ sql: String, _ args: [Any] = []) throws -> [Row] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw problem(String(cString: sqlite3_errmsg(handle))) }
        defer { sqlite3_finalize(statement) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (index, value) in args.enumerated() {
            let n = Int32(index + 1)
            if value is NSNull { sqlite3_bind_null(statement, n) }
            else if let s = value as? String { sqlite3_bind_text(statement, n, s, -1, transient) }
            else if let i = value as? Int64 { sqlite3_bind_int64(statement, n, i) }
            else if let i = value as? Int { sqlite3_bind_int64(statement, n, Int64(i)) }
            else { throw problem("Tipo de dato no admitido.") }
        }
        var result: [Row] = []; var status = sqlite3_step(statement)
        while status == SQLITE_ROW {
            var row: Row = [:]
            for index in 0..<sqlite3_column_count(statement) {
                let key = String(cString: sqlite3_column_name(statement, index))
                switch sqlite3_column_type(statement, index) {
                case SQLITE_INTEGER: row[key] = sqlite3_column_int64(statement, index)
                case SQLITE_FLOAT: row[key] = sqlite3_column_double(statement, index)
                case SQLITE_TEXT: row[key] = String(cString: sqlite3_column_text(statement, index))
                default: row[key] = NSNull()
                }
            }
            result.append(row); status = sqlite3_step(statement)
        }
        guard status == SQLITE_DONE else { throw problem(String(cString: sqlite3_errmsg(handle))) }; return result
    }
    func transaction<T>(_ work: () throws -> T) throws -> T {
        try exec("BEGIN IMMEDIATE")
        do { let value = try work(); try exec("COMMIT"); return value }
        catch { try? exec("ROLLBACK"); throw error }
    }
    func copy(to target: Database) throws {
        guard let b = sqlite3_backup_init(target.handle, "main", handle, "main") else { throw problem("No se pudo preparar la copia SQLite.") }
        let step = sqlite3_backup_step(b, -1); let finish = sqlite3_backup_finish(b)
        guard step == SQLITE_DONE, finish == SQLITE_OK else { throw problem("La copia no se completó; no se ha confirmado su restauración.") }
    }
    func backup(_ path: String) throws {
        guard !FileManager.default.fileExists(atPath: path) else { throw problem("El archivo ya existe. Usa otro nombre para la copia.") }
        let target = try Database(path)
        do { try copy(to: target); try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path) }
        catch { try? FileManager.default.removeItem(atPath: path); throw error }
    }
}

final class Store {
    static let applicationID: Int64 = 1128355121
    let db: Database
    let directory: URL
    init(directory: URL) throws {
        self.directory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let path = directory.appendingPathComponent("caudal.sqlite").path
        db = try Database(path)
        let version = num(try db.rows("PRAGMA user_version").first ?? [:], "user_version")
        guard version <= 1 else { throw problem("Estos datos requieren una versión más reciente de Caudal.") }
        let appID = num(try db.rows("PRAGMA application_id").first ?? [:], "application_id")
        guard appID == 0 || appID == Self.applicationID else { throw problem("La base de datos pertenece a otra aplicación.") }
        if version == 0 { try migrate() }
        try Self.validate(db)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path)
    }
    private func migrate() throws {
        try db.transaction {
            let schema = [
                "CREATE TABLE accounts(id TEXT PRIMARY KEY,name TEXT NOT NULL,kind TEXT NOT NULL CHECK(kind IN ('bank','cash','savings')),initial_cents INTEGER NOT NULL CHECK(abs(initial_cents)<=900000000000))",
                "CREATE TABLE categories(id TEXT PRIMARY KEY,name TEXT NOT NULL,kind TEXT NOT NULL CHECK(kind IN ('income','expense')),color TEXT NOT NULL)",
                "CREATE TABLE debts(id TEXT PRIMARY KEY,name TEXT NOT NULL,creditor TEXT NOT NULL,initial_cents INTEGER NOT NULL CHECK(initial_cents>=0),monthly_cents INTEGER NOT NULL CHECK(monthly_cents>=0),due_day INTEGER NOT NULL CHECK(due_day BETWEEN 0 AND 31),note TEXT NOT NULL)",
                "CREATE TABLE movements(id TEXT PRIMARY KEY,date TEXT NOT NULL,kind TEXT NOT NULL CHECK(kind IN ('income','expense','transfer','debt_payment','debt_draw')),amount_cents INTEGER NOT NULL CHECK(amount_cents>0),account_id TEXT NOT NULL REFERENCES accounts(id),destination_id TEXT REFERENCES accounts(id),category_id TEXT REFERENCES categories(id),debt_id TEXT REFERENCES debts(id),principal_cents INTEGER NOT NULL CHECK(principal_cents>=0 AND principal_cents<=amount_cents),note TEXT NOT NULL,deleted INTEGER NOT NULL DEFAULT 0 CHECK(deleted IN(0,1)),created_at TEXT NOT NULL)",
                "CREATE INDEX movements_date ON movements(date)",
                "CREATE INDEX movements_debt ON movements(debt_id)",
                "CREATE TABLE budgets(id TEXT PRIMARY KEY,month TEXT NOT NULL,category_id TEXT NOT NULL REFERENCES categories(id),amount_cents INTEGER NOT NULL CHECK(amount_cents>0),UNIQUE(month,category_id))",
                "CREATE TABLE goals(id TEXT PRIMARY KEY,name TEXT NOT NULL,target_cents INTEGER NOT NULL CHECK(target_cents>0),saved_cents INTEGER NOT NULL CHECK(saved_cents>=0 AND saved_cents<=target_cents),due_date TEXT NOT NULL)",
                "CREATE TABLE audit(id TEXT PRIMARY KEY,action TEXT NOT NULL,entity TEXT NOT NULL,entity_id TEXT NOT NULL,date TEXT NOT NULL,detail TEXT NOT NULL)",
                "CREATE TABLE migrations(version INTEGER PRIMARY KEY,applied_at TEXT NOT NULL)"
            ]
            for sql in schema { try db.exec(sql) }
            let defaults: [(String,String,String,String)] = [
                ("salary","Nómina","income","#2d9074"),("other-income","Otros ingresos","income","#6b8cc7"),
                ("home","Vivienda","expense","#6577c0"),("food","Alimentación","expense","#e3a153"),
                ("transport","Transporte","expense","#789faf"),("leisure","Ocio","expense","#ac83b8"),
                ("shopping","Compras","expense","#d27e83"),("health","Salud","expense","#65a497"),
                ("subscriptions","Suscripciones","expense","#c6a35c"),("education","Formación","expense","#7794d0"),
                ("interest","Intereses y comisiones","expense","#ad8170"),("other-expense","Otros gastos","expense","#9298a2")
            ]
            for c in defaults { try db.exec("INSERT INTO categories VALUES(?,?,?,?)", [c.0,c.1,c.2,c.3]) }
            try db.exec("PRAGMA application_id=\(Self.applicationID)"); try db.exec("PRAGMA user_version=1")
            try db.exec("INSERT INTO migrations VALUES(1,?)", [ISO8601DateFormatter().string(from: Date())])
        }
    }
    static func validate(_ db: Database) throws {
        guard num(try db.rows("PRAGMA application_id").first ?? [:], "application_id") == applicationID,
              num(try db.rows("PRAGMA user_version").first ?? [:], "user_version") == 1,
              str(try db.rows("PRAGMA integrity_check").first ?? [:], "integrity_check") == "ok",
              try db.rows("PRAGMA foreign_key_check").isEmpty else { throw problem("La copia no es compatible o no supera la comprobación de integridad.") }
        for table in ["accounts","categories","debts","movements","budgets","goals","audit","migrations"] { _ = try db.rows("SELECT * FROM \(table) LIMIT 1") }
        let categories = try db.rows("SELECT * FROM categories")
        let debts = try db.rows("SELECT * FROM debts")
        var balances = Dictionary(uniqueKeysWithValues: debts.map { (str($0,"id"), num($0,"initial_cents")) })
        for m in try db.rows("SELECT * FROM movements WHERE deleted=0 ORDER BY date,created_at,rowid") {
            let kind = str(m,"kind"), amount = num(m,"amount_cents"), principal = num(m,"principal_cents")
            guard Dates.valid(str(m,"date")), amount > 0, amount <= 900_000_000_000 else { throw problem("Hay movimientos con fechas o importes inválidos.") }
            switch kind {
            case "income","expense":
                guard principal == 0, categories.contains(where: { str($0,"id") == str(m,"category_id") && str($0,"kind") == kind }) else { throw problem("La categoría no coincide con el movimiento.") }
            case "transfer": guard principal == 0, !str(m,"destination_id").isEmpty, str(m,"destination_id") != str(m,"account_id") else { throw problem("Una transferencia necesita dos cuentas distintas.") }
            case "debt_draw","debt_payment":
                let id = str(m,"debt_id"); guard let balance = balances[id] else { throw problem("Deuda no localizada.") }
                if kind == "debt_draw" { guard principal == amount else { throw problem("Disposición de deuda inválida.") }; balances[id] = balance + amount }
                else {
                    guard principal >= 0, principal <= amount, principal <= balance else { throw problem("La amortización supera la deuda pendiente en esa fecha. Revisa también los pagos posteriores.") }
                    if amount > principal { guard categories.contains(where: {str($0,"id") == str(m,"category_id") && str($0,"kind") == "expense"}) else {throw problem("Selecciona una categoría para los intereses.")} }
                    balances[id] = balance - principal
                }
            default: throw problem("Tipo de movimiento desconocido.")
            }
        }
    }
    func audit(_ action: String, _ table: String, _ id: String, _ detail: String = "") throws {
        try db.exec("INSERT INTO audit VALUES(?,?,?,?,?,?)", [UUID().uuidString, action, table, id, ISO8601DateFormatter().string(from: Date()), detail])
    }
    func existing(_ table: String, _ id: String) throws -> Row? { try db.rows("SELECT * FROM \(table) WHERE id=?", [id]).first }
    func cents(_ p: Row, _ key: String, minimum: Int64 = 0) throws -> Int64 {
        guard let n = p[key] as? NSNumber, n.doubleValue.isFinite, n.doubleValue.rounded(.towardZero) == n.doubleValue, n.doubleValue >= Double(minimum), n.doubleValue <= 900_000_000_000 else { throw problem("Introduce un importe válido con un máximo de dos decimales.") }; return n.int64Value
    }
    func text(_ p: Row, _ key: String, required: Bool = true, maximum: Int = 160) throws -> String {
        let value = str(p,key).trimmingCharacters(in: .whitespacesAndNewlines)
        guard (!required || !value.isEmpty), value.count <= maximum else { throw problem("Revisa el campo \(key): debe tener entre \(required ? 1 : 0) y \(maximum) caracteres.") }; return value
    }
    @discardableResult func save(_ entity: String, _ p: Row) throws -> String {
        let tables = ["account":"accounts","category":"categories","movement":"movements","budget":"budgets","goal":"goals","debt":"debts"]
        guard let table = tables[entity] else { throw problem("Elemento desconocido.") }
        let providedID = str(p,"id")
        var id = providedID.isEmpty ? UUID().uuidString : providedID
        if entity == "budget", providedID.isEmpty, let prior = try db.rows("SELECT id FROM budgets WHERE month=? AND category_id=?",[str(p,"month"),str(p,"category_id")]).first {id = str(prior,"id")}
        let existed = try existing(table,id) != nil
        if !providedID.isEmpty, try existing(table,id) == nil { throw problem("El registro ya no existe. Actualiza la vista.") }
        try db.transaction {
            switch entity {
            case "account":
                let initial = try cents(p,"initial_cents",minimum: -900_000_000_000), kind = str(p,"kind")
                guard ["bank","cash","savings"].contains(kind) else { throw problem("Selecciona el tipo de cuenta.") }
                try db.exec("INSERT INTO accounts VALUES(?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,kind=excluded.kind,initial_cents=excluded.initial_cents", [id, try text(p,"name"), kind, initial])
            case "category":
                let kind = str(p,"kind"), color = str(p,"color")
                guard ["income","expense"].contains(kind), color.range(of:"^#[0-9A-Fa-f]{6}$",options:.regularExpression) != nil else { throw problem("Revisa el tipo o el color de la categoría.") }
                if let old = try existing(table,id), str(old,"kind") != kind { throw problem("El tipo de una categoría existente no se puede cambiar.") }
                try db.exec("INSERT INTO categories VALUES(?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,color=excluded.color", [id,try text(p,"name"),kind,color])
            case "debt":
                let due = Int(num(p,"due_day")); guard (0...31).contains(due) else { throw problem("El día de pago debe estar entre 1 y 31, o vacío.") }
                try db.exec("INSERT INTO debts VALUES(?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,creditor=excluded.creditor,initial_cents=excluded.initial_cents,monthly_cents=excluded.monthly_cents,due_day=excluded.due_day,note=excluded.note", [id,try text(p,"name"),try text(p,"creditor",required:false),try cents(p,"initial_cents"),try cents(p,"monthly_cents"),due,try text(p,"note",required:false,maximum:1000)])
            case "goal":
                let target = try cents(p,"target_cents",minimum:1), saved = try cents(p,"saved_cents"), due = str(p,"due_date")
                guard saved <= target, due.isEmpty || Dates.valid(due) else { throw problem("La reserva debe caber en el objetivo y la fecha debe ser válida.") }
                let others = num(try db.rows("SELECT coalesce(sum(saved_cents),0) AS n FROM goals WHERE id<>?",[id]).first ?? [:],"n")
                let liquid = try totals()["liquid"] ?? 0
                let oldSaved = num(try existing(table,id) ?? [:],"saved_cents")
                guard saved <= oldSaved || others + saved <= max(0,liquid) else { throw problem("No hay saldo suficiente para reservar ese dinero. Las reservas no crean saldo.") }
                try db.exec("INSERT INTO goals VALUES(?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,target_cents=excluded.target_cents,saved_cents=excluded.saved_cents,due_date=excluded.due_date", [id,try text(p,"name"),target,saved,due])
            case "budget":
                let month = str(p,"month"), category = str(p,"category_id")
                guard Dates.valid(month + "-01"), let c = try existing("categories",category), str(c,"kind") == "expense" else { throw problem("Selecciona un mes y una categoría de gasto válidos.") }
                try db.exec("INSERT INTO budgets VALUES(?,?,?,?) ON CONFLICT(month,category_id) DO UPDATE SET amount_cents=excluded.amount_cents", [id,month,category,try cents(p,"amount_cents",minimum:1)])
            case "movement":
                let date = str(p,"date"), kind = str(p,"kind")
                guard Dates.valid(date), date <= Dates.day() else { throw problem("Registra una fecha válida hasta hoy. Un pago futuro todavía no es un movimiento real.") }
                guard try existing("accounts",str(p,"account_id")) != nil else { throw problem("Selecciona una cuenta.") }
                let amount = try cents(p,"amount_cents",minimum:1)
                var destination: Any = NSNull(), category: Any = NSNull(), debt: Any = NSNull(), principal: Int64 = 0
                switch kind {
                case "income","expense": category = str(p,"category_id")
                case "transfer": destination = str(p,"destination_id")
                case "debt_payment":
                    debt = str(p,"debt_id"); principal = try cents(p,"principal_cents"); if amount > principal { category = str(p,"category_id") }
                case "debt_draw": debt = str(p,"debt_id"); principal = amount
                default: throw problem("Selecciona un tipo de movimiento.")
                }
                let created = str(try existing(table,id) ?? [:],"created_at")
                try db.exec("INSERT INTO movements VALUES(?,?,?,?,?,?,?,?,?,?,0,?) ON CONFLICT(id) DO UPDATE SET date=excluded.date,kind=excluded.kind,amount_cents=excluded.amount_cents,account_id=excluded.account_id,destination_id=excluded.destination_id,category_id=excluded.category_id,debt_id=excluded.debt_id,principal_cents=excluded.principal_cents,note=excluded.note", [id,date,kind,amount,str(p,"account_id"),destination,category,debt,principal,try text(p,"note",required:false,maximum:1000),created.isEmpty ? ISO8601DateFormatter().string(from:Date()) : created])
            default: break
            }
            try Self.validate(db); try audit(existed ? "editar" : "crear",table,id)
        }
        return id
    }
    func delete(_ entity: String, _ id: String, restore: Bool = false) throws {
        let tables = ["account":"accounts","category":"categories","movement":"movements","budget":"budgets","goal":"goals","debt":"debts"]
        guard let table = tables[entity], let old = try existing(table,id) else { throw problem("Registro no localizado.") }
        guard !restore || entity == "movement" else { throw problem("Esta operación no admite deshacer.") }
        _ = try backup()
        try db.transaction {
            if entity == "movement" { try db.exec("UPDATE movements SET deleted=? WHERE id=?",[restore ? 0 : 1,id]) }
            else { try db.exec("DELETE FROM \(table) WHERE id=?",[id]) }
            try Self.validate(db); try audit(restore ? "recuperar" : "eliminar",table,id,try json(old))
        }
    }
    func totals() throws -> [String:Int64] {
        let a = try accountRows(); let d = try debtRows()
        return ["liquid":a.reduce(0){$0+num($1,"balance_cents")},"debt":d.reduce(0){$0+num($1,"remaining_cents")},"reserved":num(try db.rows("SELECT coalesce(sum(saved_cents),0) AS n FROM goals").first ?? [:],"n")]
    }
    func accountRows() throws -> [Row] {
        let movements = try db.rows("SELECT * FROM movements WHERE deleted=0 AND date<=?",[Dates.day()])
        return try db.rows("SELECT * FROM accounts ORDER BY name COLLATE NOCASE").map { account in
            var a = account; let id = str(a,"id"); var balance = num(a,"initial_cents")
            for m in movements {
                if str(m,"account_id") == id { balance += ["income","debt_draw"].contains(str(m,"kind")) ? num(m,"amount_cents") : -num(m,"amount_cents") }
                if str(m,"destination_id") == id { balance += num(m,"amount_cents") }
            }
            a["balance_cents"] = balance; return a
        }
    }
    func debtRows() throws -> [Row] {
        let movements = try db.rows("SELECT * FROM movements WHERE deleted=0 AND date<=?",[Dates.day()])
        return try db.rows("SELECT * FROM debts ORDER BY name COLLATE NOCASE").map { debt in
            var d = debt; let ms = movements.filter {str($0,"debt_id") == str(d,"id")}
            let draws = ms.filter{str($0,"kind") == "debt_draw"}.reduce(0){$0+num($1,"amount_cents")}
            let paid = ms.filter{str($0,"kind") == "debt_payment"}.reduce(0){$0+num($1,"principal_cents")}
            d["remaining_cents"] = num(d,"initial_cents") + draws - paid; d["paid_cents"] = paid; d["drawn_cents"] = draws; return d
        }
    }
    func snapshot() throws -> Row {
        ["today":Dates.day(),"accounts":try accountRows(),"categories":try db.rows("SELECT * FROM categories ORDER BY kind,name COLLATE NOCASE"),"movements":try db.rows("SELECT * FROM movements WHERE deleted=0 ORDER BY date DESC,created_at DESC,id"),"budgets":try db.rows("SELECT * FROM budgets"),"goals":try db.rows("SELECT * FROM goals ORDER BY name COLLATE NOCASE"),"debts":try debtRows(),"totals":try totals(),"dataPath":directory.path,"audit":try db.rows("SELECT * FROM audit ORDER BY date DESC,rowid DESC LIMIT 60")]
    }
    @discardableResult func backup() throws -> String {
        let folder = directory.appendingPathComponent("Copias")
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
        let path = folder.appendingPathComponent("Caudal-\(Dates.day())-\(UUID().uuidString.prefix(8)).sqlite").path
        try db.backup(path); return path
    }
    func previewRestore(_ path: String) throws -> Row {
        let attrs = try FileManager.default.attributesOfItem(atPath:path)
        guard (attrs[.size] as? NSNumber)?.intValue ?? 0 <= 100_000_000 else { throw problem("La copia supera el límite de 100 MB.") }
        let source = try Database(path,readonly:true); try Self.validate(source)
        return ["accounts":try source.rows("SELECT * FROM accounts").count,"movements":try source.rows("SELECT * FROM movements WHERE deleted=0").count,"goals":try source.rows("SELECT * FROM goals").count,"debts":try source.rows("SELECT * FROM debts").count]
    }
    func restore(_ path: String) throws {
        _ = try previewRestore(path)
        let source = try Database(path,readonly:true)
        _ = try backup(); try source.copy(to:db); try Self.validate(db); try audit("restaurar","database","",(path as NSString).lastPathComponent)
    }
    func csv() throws -> String {
        let data = try snapshot(), accounts = data["accounts"] as? [Row] ?? [], categories = data["categories"] as? [Row] ?? []
        let names = ["income":"Ingreso","expense":"Gasto","transfer":"Transferencia","debt_payment":"Pago de deuda","debt_draw":"Dinero prestado"]
        func quote(_ value: String) -> String {
            let safe = ["=","+","-","@","\t","\r"].contains(where:{value.hasPrefix($0)}) ? "'"+value : value
            return "\""+safe.replacingOccurrences(of:"\"",with:"\"\"")+"\""
        }
        var lines = ["Fecha;Tipo;Cuenta;Destino;Categoría;Importe EUR;Principal EUR;Notas"]
        for m in data["movements"] as? [Row] ?? [] {
            func name(_ rows: [Row], _ id: String) -> String {str(rows.first{str($0,"id")==id} ?? [:],"name")}
            let amount = String(format:"%.2f",Double(num(m,"amount_cents"))/100).replacingOccurrences(of:".",with:",")
            let principal = String(format:"%.2f",Double(num(m,"principal_cents"))/100).replacingOccurrences(of:".",with:",")
            lines.append([str(m,"date"),names[str(m,"kind")] ?? "",name(accounts,str(m,"account_id")),name(accounts,str(m,"destination_id")),name(categories,str(m,"category_id")),amount,principal,str(m,"note")].map(quote).joined(separator:";"))
        }
        return "\u{FEFF}" + lines.joined(separator:"\r\n")
    }
}
