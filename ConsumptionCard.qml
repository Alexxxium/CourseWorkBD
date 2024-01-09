import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import ILS 1.0

IlsPropertyEditor {
    id: rootItem
    title: rootItem.state == "create" ?
               branchTr("Создание нового расходного материала") :
               rootItem.model.data(index) ?
                   rootItem.model.data(index) :
                   branchTr("Свойства расходного материала")
    property bool copyCreation: false

    property OrganizationsModel relatedOrganizationsModel: OrganizationsModel{
        dbConnector: rootItem.dbConnector
        reloadOnConnectorSet: false
        Component.onCompleted: rootItem.reloadOrgModel()
    }
    function reloadOrgModel()
    {
        rootItem.relatedOrganizationsModel.loadCompRelatedOrganizations(rootItem.index, rootItem.relatedOrganizationsModel)
        propSupplyOrgRow.organizationModel = null
        propSupplyOrgRow.organizationModel = rootItem.relatedOrganizationsModel
        propSupplyOrgRow.checkActualSupplyOrg()
    }

    PropertyGroup{
        title: branchTr("Расходный материал")
        iconSource: "icons/consump.png"
        editButtonVisible: rootItem.canEdit

        PropertyRow {
            id: consumpId
            name: branchTr("Обозначение")
            property int role:  ConsumptionModel.ConsIdRole
            value: if (rootItem.state != "create" || copyCreation) rootItem.model.data(index, role) + (copyCreation?branchTr(" - Копия"):"")
        }
        PropertyRow {
            id: consumpExternalId
            name: branchTr("Внешнее обозначение")
            property int role:  ConsumptionModel.ConsIdExtRole
            editable: false
            value: if (rootItem.state != "create" || copyCreation) rootItem.model.data(index, role)
        }

        PropertyRow {
            id: consumpName
            name: branchTr("Наименование")
            property int role:  ConsumptionModel.ConsNameRole
            value: if (rootItem.state != "create" || copyCreation) rootItem.model.data(index, role)
        }
        PropertyRowMultiline {
            id: consumpDescr
            name: branchTr("Описание")
            property int role:  ConsumptionModel.ConsDescrRole
            value: if (rootItem.state != "create" || copyCreation) rootItem.model.data(index, role)
        }

        PropertyRow {
            id: consumpFNN
            name: qsTr(branchTr("ФНН"))
            property int role:  ConsumptionModel.ConsNsnRole
            toolTipText: qsTr(branchTr("Федеральный номенклатурный номер"))
            toolTipEnabled: true
            validator:  RegExpValidator{
                id:intValidator
                regExp:/[0-9]*/
            }
            value: if (rootItem.state != "create" || copyCreation) rootItem.model.data(index, role)
        }

        PropertyRow {
            id: consumpStandard
            name: branchTr("Стандарт или ТУ изготовления")
            property int role:  ConsumptionModel.ConsStandardRole
            value: if (rootItem.state != "create" || copyCreation) rootItem.model.data(index, role)
        }

        PropertyRowBool {
            id: consumpIsStandard
            name: qsTr(branchTr("Стандартное изделие"))
            property int role:  ConsumptionModel.ConsIsStandartRole
            value: if (rootItem.state != "create" || copyCreation) rootItem.model.data(index, role)
        }

        PropertyRowComboBox {
            id: consumpMakeBuy
            name: qsTr(branchTr("Покупное/собственного производства"))
            property int role: ConsumptionModel.ConsMakeOrBuyRole
            model: rootItem.model.getMakeOrBuyList()
            value: if (rootItem.state != "create" || copyCreation) rootItem.model.data(index, role)
        }

        PropertyRowComboBox {
            id: consumpUnit
            name: branchTr("Единица измерения")
            property int role:  ConsumptionModel.ConsUnitResNameRole
            model: rootItem.model.getResourceNames()
            value: if (rootItem.state != "create" || copyCreation) rootItem.model.data(index, role)
        }
    }

    PropertyGroupItemSelectorRelOrganizations{
        id: propOrg
        totallyHidden: rootItem.state === "create"
        editButtonVisible: rootItem.canEdit
        onAddOrganizationRel: {
            rootItem.relatedOrganizationsModel.addCompRelatedOrganizations(idx, mod, type)
            if(type === "Поставщик")
                propSupply.state = "edit"
        }
        onDeleteOrganizationRel: {
            rootItem.relatedOrganizationsModel.deleteCompRelatedOrganization(rootItem.index, idx, mod)
            propSupplyOrgRow.checkActualSupplyOrg()
        }
        selectedItemsModel: rootItem.relatedOrganizationsModel
        deleteOrganizationRelationMessage: branchTr("Вы уверены, что хотите удалить связь расходного материала с организацией?")
        onSaveClicked: {
            propSupplyOrgRow.checkActualSupplyOrg()
            propSupplyOrgRow.newElementAdded = true
        }
    }

    PropertyGroup {
        id: propSupply
        title: branchTr("Информация о поставщиках")
        iconSource: "icons/supply.png"
        totallyHidden: rootItem.state == "create"

        editButtonVisible: rootItem.canEdit && rootItem.relatedOrganizationsModel.length > 0 && propSupplyOrgRow.isSupplierExist

        Component.onCompleted: reload()

        PropertyRowSupplyOrganizations{
            id: propSupplyOrgRow
            editable: rootItem.canEdit
            organizationModel: rootItem.relatedOrganizationsModel
            onDeleteSupplyOrgRel: {
                rootItem.relatedOrganizationsModel.deleteCompRelatedOrganization(rootItem.index, idx, organizationModel)
                propSupplyOrgRow.checkActualSupplyOrg()
            }
        }

        function reload()
        {
            propSupplyOrgRow.checkActualSupplyOrg()
        }
    }

//    PropertyGroup {
//        title: qsTr(branchTr("Показатели МТО"))
//        iconSource: "icons/rate_avail.png"
//        totallyHidden: rootItem.state == "create"
//        editButtonVisible : false
//        Component.onCompleted: rateUsageMdl.reload(rootItem.index, "mto")
//        PropertyRow{
//            id:propRow_rateMTO
//            editable: true
//            viewDelegate: delegateRateMTO
//            editDelegate: delegateRateMTO
//            Component{
//                id:delegateRateMTO
//                ListView{
//                    id:mtoRateRowList
//                    height: contentHeight
//                    spacing: 2
//                    interactive: false
//                    model:rateUsageMdl
//                    delegate:IlsRateView{
//                        id:rateRow
//                        width: parent.width
//                        rateModel: rateUsageMdl
//                        rateIndex: rateUsageMdl.index(index,0)
//                        deleteButtonVisible:false
//                        colorScheme: rootItem.colorScheme
//                    }
//                }
//            }
//        }
//    }
    onAccept: {
        var idx = rootItem.index

        //Проверяем значения
        if(!checkRowsValidators())
            return

        if(!model.checkConsumptionId(state == "create"? -1 : idx, consumpId.newValue))
            return

        if (state == "create")
        {
            var newIdx = rootItem.model.createConsumption(copyCreation ?idx.parent : idx,
                                                          consumpId.newValue)
             if (!newIdx.valid)
             {
                 return
             }

             idx = newIdx
        }

        for (var i = 0; i < propertyRows.length; i++)
        {
            if (propertyRows[i].role)
            {
                model.setData(idx, propertyRows[i].newValue, propertyRows[i].role)
            }
        }

        if(state !== "create")
        {
            rootItem.relatedOrganizationsModel.saveCompRelatedOrganizations(idx, propOrg.selectedItemsModel)
            propSupplyOrgRow.checkActualSupplyOrg()
            propSupplyOrgRow.saveSupplyOrgValues()
        }

        if(state == "create")
            indexCreated(newIdx)

        rootItem.state = "view"

    }

    onReject: {
        rootItem.reloadOrgModel()
    }
    RateModel {
        id:rateUsageMdl
        dbConnector: rootItem.dbConnector
    }
}

