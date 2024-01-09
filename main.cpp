#include <QDir>
#include <QIcon>
#include <QQmlContext>
#include <QApplication>
#include <QCoreApplication>
#include <QQmlApplicationEngine>

#include "CourseWorkDB.h"



int main(int argc, char *argv[])
{
    CourseWorkDB backend;
    constexpr auto
        appicon = ":/app.ico",
        appname = "Курсовая работа 'Проектирование базы данных на платформе PSS'";

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    app.setApplicationName(appname);

    QQmlApplicationEngine engine;
    engine.addPluginPath(QCoreApplication::applicationDirPath() + "/imports/ILS");

    engine.rootContext()->setContextProperty("appArguments", app.arguments());
    engine.rootContext()->setContextProperty("appName", appname);
    engine.rootContext()->setContextProperty("backend", &backend);

    auto imports_dir = QDir::toNativeSeparators(QCoreApplication::applicationDirPath() + "/imports");
    app.setWindowIcon(QIcon(appicon));
    engine.addImportPath(imports_dir);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);

        }, Qt::QueuedConnection);
    engine.load(url);
    app.exec();

    return qApp ? qApp->exec() : 0;
}
