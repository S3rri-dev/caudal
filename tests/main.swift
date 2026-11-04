// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 S3rri-dev y colaboradores.
import Foundation

var checks = 0
func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
    guard try condition() else {throw problem("FALLO: \(message)")}; checks += 1
}
func rejects(_ message: String, _ body: () throws -> Void) throws {
    var rejected = false; do {try body()} catch {rejected = true}; try expect(rejected,message)
}
let root = FileManager.default.temporaryDirectory.appendingPathComponent("finanzas-tests-\(UUID().uuidString)")
defer {try? FileManager.default.removeItem(at:root)}
do {
    let store = try Store(directory:root.appendingPathComponent("data"))
    let today = Dates.day()
    try expect((try store.accountRows()).isEmpty,"Primer arranque sin dinero ficticio")
    try expect(try store.db.rows("SELECT * FROM categories").count == 12,"Categorías disponibles sin crear movimientos")
    let bank = try store.save("account",["name":"Principal","kind":"bank","initial_cents":100000])
    let savings = try store.save("account",["name":"Ahorro","kind":"savings","initial_cents":0])
    func move(_ kind: String, _ amount: Int64, _ extra: Row = [:]) throws -> String {
        var p: Row = ["date":today,"kind":kind,"amount_cents":amount,"account_id":bank,"category_id":kind == "income" ? "salary" : "food","note":"Prueba","principal_cents":0]
        p.merge(extra){_,v in v}; return try store.save("movement",p)
    }
    let income = try move("income",140000)
    let expense = try move("expense",12345)
    _ = try move("transfer",20000,["destination_id":savings])
    try expect(try store.totals()["liquid"] == 227655,"Transferencia no cambia patrimonio líquido")
    try expect(num(try store.accountRows().first{str($0,"id")==bank} ?? [:],"balance_cents") == 207655,"Saldo de origen correcto")
    try expect(num(try store.accountRows().first{str($0,"id")==savings} ?? [:],"balance_cents") == 20000,"Saldo de destino correcto")
    try rejects("Rechaza transferencia a la misma cuenta") {_ = try move("transfer",1,["destination_id":bank])}
    try rejects("Rechaza cuenta inexistente") {_ = try move("income",1,["account_id":"missing"])}
    try rejects("Rechaza categoría incorrecta") {_ = try move("expense",1,["category_id":"salary"])}
    try rejects("Rechaza importe cero") {_ = try move("expense",0)}
    try rejects("Rechaza importe negativo") {_ = try move("expense",-100)}
    try rejects("Rechaza céntimos fraccionarios") {_ = try store.save("movement",["date":today,"kind":"expense","amount_cents":1.5,"account_id":bank,"category_id":"food","note":""])}
    try rejects("Rechaza fecha futura como gasto real") {_ = try move("expense",1,["date":"2099-01-01"])}
    try rejects("Rechaza fecha imposible") {_ = try move("expense",1,["date":"2026-02-30"])}
    try expect(try store.db.rows("SELECT * FROM movements").count == 3,"Errores no dejan movimientos parciales")
    let debt = try store.save("debt",["name":"Préstamo","creditor":"Banco","initial_cents":50000,"monthly_cents":11000,"due_day":5,"note":""])
    try expect(try store.totals()["liquid"] == 227655,"Deuda inicial no se convierte en dinero recibido")
    _ = try move("debt_payment",11000,["debt_id":debt,"principal_cents":10000,"category_id":"interest"])
    try expect(try store.totals()["liquid"] == 216655,"Cuota completa reduce el saldo")
    try expect(try store.totals()["debt"] == 40000,"Solo el principal reduce deuda")
    _ = try move("debt_draw",20000,["debt_id":debt])
    try expect(try store.totals()["liquid"] == 236655,"Préstamo recibido aumenta saldo")
    try expect(try store.totals()["debt"] == 60000,"Préstamo recibido aumenta principal")
    try rejects("No permite amortizar más deuda de la pendiente") {_ = try move("debt_payment",90000,["debt_id":debt,"principal_cents":90000])}
    try rejects("No permite principal superior al pago") {_ = try move("debt_payment",1000,["debt_id":debt,"principal_cents":2000])}
    let zeroDebt = try store.save("debt",["name":"Financiación nueva","initial_cents":0,"monthly_cents":0,"due_day":0])
    let draw = try move("debt_draw",25000,["debt_id":zeroDebt])
    _ = try move("debt_payment",24000,["debt_id":zeroDebt,"principal_cents":24000])
    try rejects("Borrar un préstamo usado por cuotas no permite saldo negativo de deuda") {try store.delete("movement",draw)}
    try expect(num(try store.existing("movements",draw) ?? [:],"deleted") == 0,"Borrado inválido se revierte íntegramente")
    let goal = try store.save("goal",["name":"Viaje","target_cents":100000,"saved_cents":50000,"due_date":""])
    let balance = try store.totals()["liquid"]
    try expect(balance == 237655,"Reservar ahorro no mueve saldo")
    try expect(try store.totals()["reserved"] == 50000,"Reserva guardada")
    try rejects("No reserva más dinero del disponible") {_ = try store.save("goal",["name":"Imposible","target_cents":999999,"saved_cents":999999,"due_date":""])}
    try rejects("No reserva por encima del objetivo") {_ = try store.save("goal",["name":"Mal","target_cents":100,"saved_cents":101,"due_date":""])}
    _ = try store.save("budget",["month":String(today.prefix(7)),"category_id":"food","amount_cents":30000])
    _ = try store.save("budget",["month":String(today.prefix(7)),"category_id":"food","amount_cents":35000])
    try expect(try store.db.rows("SELECT * FROM budgets").count == 1,"Presupuestos sin duplicados por mes/categoría")
    try expect(num(try store.db.rows("SELECT * FROM budgets").first ?? [:],"amount_cents") == 35000,"Repetir categoría actualiza límite")
    try rejects("No acepta presupuesto de ingresos") {_ = try store.save("budget",["month":String(today.prefix(7)),"category_id":"salary","amount_cents":1])}
    try rejects("No elimina cuenta con movimientos") {try store.delete("account",bank)}
    try rejects("No elimina categoría con movimientos") {try store.delete("category","food")}
    try store.delete("movement",expense)
    try expect(try store.totals()["liquid"] == balance! + 12345,"Eliminar gasto recalcula saldo")
    try store.delete("movement",expense,restore:true)
    try expect(try store.totals()["liquid"] == balance,"Deshacer restaura saldo exacto")
    try store.delete("movement",expense,restore:true)
    try expect(try store.totals()["liquid"] == balance,"Recuperar dos veces no duplica dinero")
    _ = try store.save("movement",["id":expense,"date":today,"kind":"expense","amount_cents":13000,"account_id":bank,"category_id":"food","note":"Corregido"])
    try expect(try store.totals()["liquid"] == balance! - 655,"Editar gasto aplica solo la diferencia")
    _ = try store.save("movement",["id":expense,"date":today,"kind":"expense","amount_cents":12345,"account_id":bank,"category_id":"food","note":"=SUM(A1:A2)"])
    try expect(try store.csv().contains("'=SUM(A1:A2)"),"CSV neutraliza fórmulas en texto")
    _ = try move("expense",1); _ = try move("expense",2)
    try expect(try store.totals()["liquid"] == balance! - 3,"Céntimos exactos sin redondeo de coma flotante")
    let backup = try store.backup()
    try expect(num(try store.previewRestore(backup),"accounts") == 2,"Vista previa de copia validada")
    _ = try move("expense",1000)
    try store.restore(backup)
    try expect(try store.totals()["liquid"] == balance! - 3,"Restauración recupera saldos completos")
    try expect(try store.db.rows("SELECT * FROM goals").count == 1,"Restauración incluye objetivos")
    try expect(try store.db.rows("SELECT * FROM budgets").count == 1,"Restauración incluye presupuestos")
    let before = try store.totals()
    let invalid = root.appendingPathComponent("invalid.sqlite"); try Data("No soy SQLite".utf8).write(to:invalid)
    try rejects("Copia corrupta no se restaura") {try store.restore(invalid.path)}
    try expect(try store.totals() == before,"Restauración inválida no cambia datos")
    let foreign = try Database(root.appendingPathComponent("other.sqlite").path); try foreign.exec("CREATE TABLE other(id TEXT)")
    try rejects("Base ajena no se restaura") {try store.restore(root.appendingPathComponent("other.sqlite").path)}
    let newer = root.appendingPathComponent("newer.sqlite"); try store.db.backup(newer.path)
    let future = try Database(newer.path);try future.exec("PRAGMA user_version=99")
    try rejects("Versión incompatible se rechaza") {try store.restore(newer.path)}
    let reopened = try Store(directory:root.appendingPathComponent("data"))
    try expect(try reopened.totals() == before,"Reabrir conserva todos los saldos")
    try expect(try reopened.db.rows("SELECT * FROM migrations").count == 1,"Reabrir no repite migración")
    try expect(try reopened.existing("movements",income) != nil,"Reabrir conserva ingresos")
    try expect(try reopened.existing("goals",goal) != nil,"Reabrir conserva reservas")
    try expect(Dates.valid("2028-02-29") && !Dates.valid("2027-02-29"),"Calendario real y años bisiestos")
    try expect(try store.db.rows("PRAGMA foreign_key_check").isEmpty,"Integridad referencial final")
    print("OK · \(checks) comprobaciones: saldos, deudas, presupuestos, reservas, edición, errores, copias y persistencia.")
} catch {fputs("\(error.localizedDescription)\n",stderr);exit(1)}
