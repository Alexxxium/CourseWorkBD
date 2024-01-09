QT += quick widgets
CONFIG  += c++11
TARGET = CourseWorkDB

DEFINES += QT_DEPRECATED_WARNINGS

HEADERS += \
    CourseWorkDB.h

SOURCES += \
        CourseWorkDB.cpp \
        main.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH += $$PWD/../ILSQMLPlugin/imports


# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

win32:CONFIG(release, debug|release): LIBDIR = /release
else:win32:CONFIG(debug, debug|release): LIBDIR = /debug
RC_ICONS = $$PWD/app.ico


include(../LibAdders.pri)

$$addLibs(     \
     ilsModule \
)
$$addCoreLibs()

# Kerberos
win32: LIBS += -lSecur32
else:unix:LIBS += -lkrb5 -lgssapi_krb5


