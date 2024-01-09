import QtQuick 2.11
import QtQuick.Layouts 1.15
import ILS 1.0


IlsPage {
    id: rootItem

    IlsContextMenu {
        id: contextMenu
        menuBar: menuBar
    }

    IlsBusyIndicator {
        id: indicator
    }

    ErrorPopup {
        id: errPopup
        colorScheme: rootItem.colorScheme
    }

    // Главная модель
    ConsumptionModel {
        id: mainModel
        dbConnector: rootItem.dbConnector
        onInfo: errPopup.showInfo(message)
        onError: errPopup.showCritical(error)
        onBusyChanged: indicator.running = busy
    }

    // Карточка папки
    Component {
        id: propertyEditorFolder
        PropertyEditorFolder {
            dbConnector: rootItem.dbConnector
            colorScheme: rootItem.colorScheme
            model: mainModel
            index: treeView.curIndex
            onIndexChanged: treeView.setSelectedIndex(newIndex)
            onClose: {
                treeView.selection.clear()
                sideBar().close()
            }
        }
    }

    // Карточка изделия
    Component {
        id: propertyEditorConsumption
        ConsumptionCard {
            dbConnector: rootItem.dbConnector
            colorScheme: rootItem.colorScheme
            model: mainModel
            index: treeView.curIndex
            onIndexChanged: treeView.setSelectedIndex(newIndex)
            onClose: {
                treeView.selection.clear()
                sideBar().close()
            }
        }
    }

    // Поисковик
    Component {
        id: finder
        IlsFinderItem {
            colorScheme: rootItem.colorScheme
            model: mainModel
            searchingTypes: [branchTr("Расходный материал"), branchTr("Папка")]
            onAboutToClose: sideBar().close()
            onSearchResultIndexAdded: indicator.setRunForFunction(function() {
                treeView.expand(index)
                treeView.__listView.positionViewAtIndex(treeView.getRealRow(index) - 1, ListView.Center)
            })
        }
    }


    headerDelegate: IlsPageHeader {
        menuBar: menuBar
        centralItem: RowLayout {
            spacing: 0
            Item {
                Layout.fillWidth: true
            }
            IlsPageHeaderSearchField {
                __view: treeView
                colorScheme: rootItem.colorScheme
                enabled: !sideBar().dim
            }
        }
    }


    menuDelegate: MenuBar {
        id: menuBar
        __view: treeView
        readonly property string disabledCauseTextByIsAllRead:
            branchTr("Недостаточно прав для выполнения операции!")

        MenuGroup {
            title: branchTr("Работа с базкой данных")
            MenuItem {
                text: branchTr("Сохранить изменения")
                iconSource: "icons/magnifier.png"
                onClicked: sideBar().setContent(finder)
            }
            MenuItem {
                text: branchTr("Обновить дерево")
                iconSource: "icons/refresh.png"
                onClicked: {
                    rootItem.dbConnector.reload()
                    mainModel.reload()
                }
            }
            MenuItem {
                text: branchTr("Поиск")
                iconSource: "icons/magnifier.png"
                onClicked: sideBar().setContent(finder);
            }
        }

        MenuGroup {
            title: "Работа с объектом"
            visible: rootItem.dbConnector.isAllRead || !mainModel.isUserReadOnly()

            MenuItem {
                id: addClassSystem
                text: branchTr("Создать папку")
                iconSource: "icons/folder.png"
                enabled: rootItem.dbConnector.isAllRead ? false : currType() === Enums.ROOT || currType() === Enums.FOLDER
                disabledCauseText: rootItem.dbConnector.isAllRead ?
                    menuBar.disabledCauseTextByIsAllRead : branchTr("Для создания папки необходимо выбрать папку!")
                onClicked: sideBar().setContent(propertyEditorFolder, "create")
            }
            MenuItem {
                text: branchTr("Создать расходный материал")
                iconSource: "icons/consump.png"
                disabledCauseText: rootItem.dbConnector.isAllRead ?
                    menuBar.disabledCauseTextByIsAllRead : branchTr("Для создания расходного материала необходимо выбрать папку!")
                onClicked: sideBar().setContent(propertyEditorConsumption, "create")
            }
            MenuItem {
                text: branchTr("Создать копию объекта")
                iconSource: "icons/copy.png"
                enabled: rootItem.dbConnector.isAllRead ? false : currType() === Enums.CONSUMPTION &&
                    [Enums.UNCLASSIFIED_FOLDER, Enums.ROOT, Enums.SEARCH_ITEM].indexOf(currType(treeView.curIndex.parent)) < 0

                disabledCauseText: {
                    if(currType() === Enums.CONSUMPTION &&
                        [Enums.UNCLASSIFIED_FOLDER, Enums.ROOT, Enums.SEARCH_ITEM].indexOf(currType(treeView.curIndex.parent)) >= 0) {
                        return branchTr("Невозможно создать копию выбранного объекта в системной папке!")
                    }
                    return rootItem.dbConnector.isAllRead ? menuBar.disabledCauseTextByIsAllRead :
                        branchTr("Невозможно создать копию выбранного объекта! Выберите расходный материал для создания копии!")
                }

                onClicked: {
                    sideBar().setContent(propertyEditorConsumption, "create")
                    sideBar().item.copyCreation = true
                }
            }
            MenuItem {
                text: branchTr("Удалить элемент")
                iconSource: "icons/delete.png"
                visible: mainModel.canDeleteInst(treeView.curIndex)
                enabled: rootItem.dbConnector.isAllRead ? false : currType() === Enums.FOLDER || currType() === Enums.CONSUMPTION
                disabledCauseText: rootItem.dbConnector.isAllRead ? menuBar.disabledCauseTextByIsAllRead : branchTr("Выберите объект для удаления!")
                onClicked: mainModel.deleteElements(treeView.selectedIndexes)
            }
            MenuItem {
                text: branchTr("Удалить связь")
                iconSource: "icons/delete_link.png"
                visible: mainModel.canDeleteInst(treeView.curIndex)
                enabled: rootItem.dbConnector.isAllRead ? false :
                    currType() === Enums.CONSUMPTION && [Enums.UNCLASSIFIED_FOLDER, Enums.ROOT, Enums.SEARCH_ITEM].indexOf(currType(treeView.curIndex.parent)) < 0

                disabledCauseText: {
                    if(rootItem.dbConnector.isAllRead)
                        return menuBar.disabledCauseTextByIsAllRead
                    else if([Enums.UNCLASSIFIED_FOLDER, Enums.ROOT, Enums.SEARCH_ITEM].indexOf(currType(treeView.curIndex.parent)) >= 0)
                        return branchTr("Невозможно удалить связь с системной папкой!")
                    return branchTr("Выберите объект для удаления связи!")
                }

                onClicked: deleteLinkQuestion.showYesNo(branchTr("Вы уверены, что хотите удалить связь с родительским элементом?"))

                ErrorPopup{
                    id:deleteLinkQuestion
                    onAccept: mainModel.deleteLinkWithParent(treeView.curIndex)
                }
            }
        }

        MenuGroup {
            title: branchTr("Редактирование")
            visible: !mainModel.isUserReadOnly()
            enabled: currType() === Enums.UNCLASSIFIED_FOLDER
            disabledCauseText: branchTr("Необходимо выбрать элемент")

            MenuItem {
                text: branchTr("Копировать")
                iconSource: "icons/copy.png"
                enabled: currType() === Enums.CONSUMPTION
                disabledCauseText: branchTr("Необходимо выбрать расходный материал!")
                onClicked: mainModel.copy(treeView.selectedIndexes)
            }
            MenuItem {
                id: cutButton
                text: branchTr("Вырезать")
                iconSource: "icons/cut.png"
                enabled: currType() !== Enums.ROOT && currType() !== Enums.UNCLASSIFIED_FOLDER
                disabledCauseText: branchTr("Необходимо выбрать элемент!")
                onClicked: treeView.cut()
            }
            MenuItem {
                text: branchTr("Вставить")
                iconSource: "icons/paste.png"
                enabled: currType() !== Enums.CONSUMPTION && currType() !== Enums.UNCLASSIFIED_FOLDER && !rootItem.dbConnector.isAllRead
                disabledCauseText: rootItem.dbConnector.isAllRead ?
                    menuBar.disabledCauseTextByIsAllRead : branchTr("Необходимо выбрать папку для вставки элемента!")
                onClicked: mainModel.paste(treeView.curIndex);
            }
        }

        MenuGroup {
            title: branchTr("Работа с деревом")
            enabled: currType() !== Enums.ROOT
            disabledCauseText: branchTr("Необходимо выбрать элемент!")

            MenuItem {
                text: branchTr("Открыть/закрыть окно свойств выбранного элемента")
                iconSource: "icons/properties.png"
                enabled: currType() !== Enums.ROOT && currType() !== Enums.UNCLASSIFIED_FOLDER
                disabledCauseText: branchTr("Необходимо выбрать элемент для отображения свойств!")
                onClicked: {
                    if (sideBar().content)
                        sideBar().close()
                    else
                        openPropertyCard()
                }
            }
            MenuItem {
                text: branchTr("Развернуть дерево выбранного элемента")
                iconSource: "icons/expand_node.png"
                enabled: {
                    if(currType() !== Enums.ROOT)
                        for(let index in treeView.selectedIndexes)
                            if(mainModel.rowCount(treeView.selectedIndexes[index]))
                                return true
                    return false
                }
                disabledCauseText: branchTr("Необходимо выбрать элемент для раскрытия!")
                onClicked: treeView.expandCurrentNode(treeView.selectedIndexes)
            }
        }

        MenuGroup {
            title: branchTr("Работа с данными")
            MenuItem {
                text: qsTr(branchTr("Экспорт в XML"))
                iconSource: "icons/xml_save.png"
                enabled: currType() !== Enums.ROOT &&
                         currType() !== Enums.UNCLASSIFIED_FOLDER &&
                         currType(treeView.curIndex.parent) !== Enums.UNCLASSIFIED_FOLDER
                disabledCauseText: qsTr(branchTr("Необходимо выбрать элементы для экспорта!"))
                onClicked: mainModel.exportXml(treeView.selectedIndexes)
            }
            MenuItem {
                text: qsTr(branchTr("Импорт из XML"))
                iconSource: "icons/xml_save.png"
                enabled: !mainModelInstance.isUserReadOnly() &&
                         !rootItem.dbConnector.isAllRead &&
                         currType() !== Enums.ROOT &&
                         currType() !== Enums.CONSUMPTION &&
                         currType() !== Enums.UNCLASSIFIED_FOLDER &&
                         currType(treeView.curIndex.parent) !== Enums.UNCLASSIFIED_FOLDER
                disabledCauseText: mainModel.isUserReadOnly() || rootItem.dbConnector.isAllRead ?
                    branchTr("Недостаточно прав для выполнения операции!") :
                    branchTr("Для импорта необходимо выбрать папку!")
                onClicked: mainModel.importFromXml(treeView.curIndex)
            }
        }

        MenuGroup {
            title: branchTr("Задания к курсовой работе")

            MenuItem {
                text: branchTr("Макрос")
                iconSource: "icons/toMsi.png"
                toolTipText: branchTr("Содержимое папки (изделия и дочерние папки)")
                enabled: currType() === Enums.FOLDER
                onClicked: {
                    const res = backend.macros(currItem());
                    let out;
                    for(let i = 0; i < res.length; ++i) {
                        out += res[i] + '\n'
                    }
                    errPopup.showInfo(branchTr(out))
                }
            }
            MenuItem {
                text: branchTr("Запрос 1")
                iconSource: "icons/toMsi.png"
                toolTipText: branchTr("Найти все пустые папки")
                onClicked: errPopup.showInfo(backend.query1())
            }
            MenuItem {
                text: branchTr("Запрос 2")
                iconSource: "icons/toMsi.png"
                toolTipText: branchTr("Найти все смазки, сделанные по ГОСТ стандарту")
                onClicked: errPopup.showInfo(backend.query2())
            }
            MenuItem {
                text: branchTr("Запрос 3")
                iconSource: "icons/toMsi.png"
                toolTipText: branchTr("Найти изделия, сделанные по стандартам 'ГОСТ 9754-76' и 'ГОСТ 9569-79'")
                onClicked: errPopup.showInfo(backend.query3())
            }
        }
    }

    bodyDelegate: IlsTreeView {
        id: treeView
        model: mainModel
        busyIndicator: indicator
        colorScheme: rootItem.colorScheme
        anchors.fill: parent
        sortIndicatorColumn: 0
        onContextMenuRequested: contextMenu.popup()
        onCurIndexChanged: openPropertyCard()

        IlsTableViewColumn {
            id: column
            title: ""
            role: "struct"
        }
    }


    function openPropertyCard() {
        switch (mainModel.getIndexItemType(treeView.curIndex)) {
        case Enums.FOLDER:
            sideBar().setContent(propertyEditorFolder)
            break
        case Enums.CONSUMPTION:
            sideBar().setContent(propertyEditorConsumption)
            break;
        default:
            sideBar().close()
        }
    }

    function currType(index = treeView.curIndex) {
        return mainModel.getIndexItemType(index)
    }
    function currItem(index = treeView.curIndex) {
        return mainModel.getInstanceId(index)
    }
}
