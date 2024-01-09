#ifndef COURSEWORKDB_H
#define COURSEWORKDB_H

#include <QObject>
#include <DbConnector.h>

class CourseWorkDB: public QObject
{
    Q_OBJECT

public:
    CourseWorkDB(QObject *parent = nullptr);

public slots:
    QStringList macros(const QString &id);
    QString query1();
    QString query2();
    QString query3();

private:
    DbConnector *m_db;
    bool connectSt();
    void attachMngrs();
    void detachMngrs();
};


#endif // COURSEWORKDB_H
