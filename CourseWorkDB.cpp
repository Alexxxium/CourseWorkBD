#include <QDebug>
#include <DbConnector.h>
#include <ilsPreFolderManager.h>
#include <ilsPreConsumptionManager.h>
#include "CourseWorkDB.h"



CourseWorkDB::CourseWorkDB(QObject *parent):
    QObject(parent),
    m_db(nullptr)
{
}

bool CourseWorkDB::connectSt() {
    if(!m_db) m_db = new DbConnector;
    if(m_db->isConnected() || m_db->connect(false)) {
        attachMngrs();
        return true;
    }
    return false;
}


void CourseWorkDB::attachMngrs() {
    if(!m_db->m_folderMgr) {
        m_db->m_folderMgr = new ilsPreFolderManager(*m_db);
        m_db->m_folderMgr->attach();
    }
    if(!m_db->m_consumptionMgr) {
        m_db->m_consumptionMgr = new ilsPreConsumptionManager(*m_db);
        m_db->m_consumptionMgr->attach();
    }
}
void CourseWorkDB::detachMngrs() {
    if(m_db->m_folderMgr) {
        m_db->m_folderMgr->detach();
        delete m_db->m_folderMgr;
        m_db->m_folderMgr = nullptr;
    }
    if(m_db->m_consumptionMgr) {
        m_db->m_consumptionMgr->detach();
        delete m_db->m_consumptionMgr;
        m_db->m_consumptionMgr = nullptr;
    }
}


QStringList CourseWorkDB::macros(const QString &id) {
    if(!connectSt()) {
        return { "Can`t connect to data base!" };
    }

    // Подгружаем из бд экземпляр по id вместе с атрибутами
    CaplInstance *parent = m_db->m_api.m_data.GetInstById(id.toInt());
    m_db->m_api.LoadItemInfo(parent);

    // Подгружаем контент родительской папки
    aplExtent consumptions;
    m_db->m_api.m_data.GetAttr(parent, m_db->m_folderMgr->a_folder_content, consumptions);
    m_db->m_api.LoadExtentInfo(consumptions);

    // Строим запрос на те папки у которых родитель наш экземпляр
    QString querydata = "SELECT Ext FROM Ext{apl_folder.parent = #%1} END_SELECT";
    CString query = QS2CS(querydata.arg(id));

    // Выполняем запрос и подгружаем атрибуты
    aplExtent folders;
    if(m_db->m_api.m_data.NET_QueryEditParse(query)) {
        if(!m_db->m_api.m_data.NET_QueryExecute(folders)) {
            return { "Can`t execute query!" };
        }
    }
    else {
        return { "Can`t parse query!" };
    }
    m_db->m_api.LoadExtentInfo(folders);

    // Возвращаем содержимое (работа с кэшом)
    CString buff;
    QStringList out;
    for(auto inst: folders) {
        m_db->m_api.m_data.GetAttr(inst, m_db->m_folderMgr->a_folder_name, buff);
        out << "Folder:     \t" + CS2QS(buff);
    }
    for(auto inst: consumptions) {
        m_db->m_api.m_data.GetAttr(inst, m_db->m_consumptionMgr->a_ils_consumption_name, buff);
        out << "Consumption:\t" + CS2QS(buff);
    }
    return out;
}


QString CourseWorkDB::query1() {
    if(!connectSt()) {
        return "Can`t connect to data base!";
    }

    CString query =
        "SELECT Ext FROM "
        "Ext{apl_folder.content aggr_empty} "
        "END_SELECT";

    aplExtent folders;
    if(m_db->m_api.m_data.NET_QueryEditParse(query)) {
        if(!m_db->m_api.m_data.NET_QueryExecute(folders)) {
            return "Can`t execute query!";
        }
    }
    else {
        return "Can`t parse query!";
    }
    m_db->m_api.LoadExtentInfo(folders);

    CString buff;
    QString outstr;
    QTextStream out(&outstr);
    for(auto inst: folders) {
        m_db->m_api.m_data.GetAttr(inst, m_db->m_folderMgr->a_folder_name, buff);
        out << CS2QS(buff) << '\n';
    }
    return outstr;
}

QString CourseWorkDB::query2() {
    if(!connectSt()) {
        return "Can`t connect to data base!";
    }

    CString query =
        "SELECT Ext FROM "
        "Ext{ils_consumption(.name LIKE 'Смазка' AND .standard LIKE 'ГОСТ')} "
        "END_SELECT";

    aplExtent consumptions;
    if(m_db->m_api.m_data.NET_QueryEditParse(query)) {
        if(!m_db->m_api.m_data.NET_QueryExecute(consumptions)) {
            return "Can`t execute query!";
        }
    }
    else {
        return "Can`t parse query!";
    }
    m_db->m_api.LoadExtentInfo(consumptions);

    CString buff;
    QString outstr;
    QTextStream out(&outstr);
    for(auto inst: consumptions) {
        m_db->m_api.m_data.GetAttr(inst, m_db->m_consumptionMgr->a_ils_consumption_name, buff);
        out << CS2QS(buff) << '\n';
    }
    return outstr;
}

QString CourseWorkDB::query3() {
    if(!connectSt()) {
        return "Can`t connect to data base!";
    }

    CString query =
        "SELECT Ext FROM "
        "Ext{ils_consumption(.standard = 'ГОСТ 9754-76' OR .standard = 'ГОСТ 9569-79')} "
        "END_SELECT";
    aplExtent consumptions;
    if(m_db->m_api.m_data.NET_QueryEditParse(query)) {
        if(!m_db->m_api.m_data.NET_QueryExecute(consumptions)) {
            return "Can`t execute query!";
        }
    }
    else {
        return "Can`t parse query!";
    }
    m_db->m_api.LoadExtentInfo(consumptions);

    CString buff1, buff2;
    QString outstr;
    QTextStream out(&outstr);
    for(auto inst: consumptions) {
        m_db->m_api.m_data.GetAttr(inst, m_db->m_consumptionMgr->a_ils_consumption_name, buff1);
        m_db->m_api.m_data.GetAttr(inst, m_db->m_consumptionMgr->a_ils_consumption_description, buff2);
        out << CS2QS(buff1) << ": " << CS2QS(buff2) << '\n';
    }
    return outstr;
}
