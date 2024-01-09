import QtQuick 2.11
import QtQuick.Window 2.11
import ILS 1.0


IlsModule {
    width: 1600
    height: 900
    minimumWidth: 1160
    minimumHeight: 700

    colorScheme: ColorScheme {
        sidebarOpenWidth: mainWindow.width * 0.45
        scheme: "tea"
    }
    onConnected: {
        ilsModule.content().clear()
        ilsModule.content().push(mainPage)
    }
    Component {
        id: mainPage
       CourseWorkBDMainPage {}
    }
}
