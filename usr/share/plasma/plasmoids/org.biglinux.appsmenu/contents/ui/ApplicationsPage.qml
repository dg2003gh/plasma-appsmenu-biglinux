/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Templates 2.15 as T
import QtQml 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.private.kicker 0.1 as Kicker

BasePage {
    id: root
    sideBarComponent: KickoffListView {
        id: sideBar
        focus: true // needed for Loaders
        model: plasmoid.rootItem.rootModel
        // needed otherwise app displayed at top-level will show a first character as group.
        section.property: ""
        delegate: KickoffListDelegate {
            width: view.availableWidth
            isCategory: model.hasChildren
        }
    }
    contentAreaComponent: VerticalStackView {

        popEnter: Transition {
            NumberAnimation {
                properties: "x"
                from: 0.5 * root.width
                to: 0
                duration: PlasmaCore.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation { property: "opacity"
                from: 0.0
                to: 1.0
                duration: PlasmaCore.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        pushEnter: Transition {
            NumberAnimation {
                properties: "x"
                from: 0.5 * -root.width
                to: 0
                duration: PlasmaCore.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation { property: "opacity"
                from: 0.0
                to: 1.0
                duration: PlasmaCore.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        id: stackView
        
        readonly property string preferredFavoritesViewObjectName: plasmoid.configuration.favoritesDisplay == 0 ? "favoritesGridView" : "favoritesListView"
        readonly property Component preferredFavoritesViewComponent: plasmoid.configuration.favoritesDisplay == 0 ? favoritesGridViewComponent : favoritesListViewComponent
        readonly property string preferredAppsViewObjectName: plasmoid.configuration.applicationsDisplay == 0 ? "applicationsGridView" : "applicationsListView"
        readonly property Component preferredAppsViewComponent: plasmoid.configuration.applicationsDisplay == 0 ? applicationsGridViewComponent : applicationsListViewComponent
        readonly property string preferredSystemViewObjectName: plasmoid.configuration.systemDisplay == 0 ? "systemGridView" : "systemListView"
        readonly property Component preferredSystemViewComponent: plasmoid.configuration.systemDisplay == 0 ? systemGridViewComponent : systemListViewComponent
        
        // NOTE: The 0 index modelForRow isn't supposed to be used. That's just how it works.
        // But to trigger model data update, set initial value to 0
        property int appsModelRow: 0
        readonly property Kicker.AppsModel appsModel: plasmoid.rootItem.rootModel.modelForRow(appsModelRow)
        focus: true
        initialItem: plasmoid.configuration.showFavoritesCategory == true ? preferredFavoritesViewComponent : preferredAppsViewComponent
        
        Kicker.SystemModel {
            id: systemModel
            favoritesModel: rootModel.systemFavoritesModel
        }
        
        Component {
            id: favoritesListViewComponent
            DropAreaListView {
                id: favoritesListView
                objectName: "favoritesListView"
                mainContentView: true
                focus: true
                model: plasmoid.rootItem.rootModel.favoritesModel
            }
        }

        Component {
            id: favoritesGridViewComponent
            DropAreaGridView {
                id: favoritesGridView
                objectName: "favoritesGridView"
                focus: true
                model: plasmoid.rootItem.rootModel.favoritesModel
            }
        }

        Component {
            id: applicationsListViewComponent

            KickoffListView {
                id: applicationsListView
                objectName: "applicationsListView"
                mainContentView: true
                model: stackView.appsModel
                section.property: model && model.description == "KICKER_ALL_MODEL" ? "group" : ""
                section.criteria: ViewSection.FirstCharacter
                hasSectionView: stackView.appsModelRow === 1

                onShowSectionViewRequested: {
                    stackView.push(applicationsSectionViewComponent, {
                        "currentSection": sectionName,
                        "parentView": applicationsListView
                    });
                }
            }
        }
        
        Component {
            id: applicationsSectionViewComponent

            SectionView {
                id: sectionView
                model: stackView.appsModel.sections
                onHideSectionViewRequested: {
                    stackView.pop();
                    stackView.currentItem.view.positionViewAtIndex(index, ListView.Beginning);
                    stackView.currentItem.currentIndex = index;
                }
            }
        }

        Component {
            id: applicationsGridViewComponent
            KickoffGridView {
                id: applicationsGridView
                objectName: "applicationsGridView"
                model: stackView.appsModel
            }
        }
        
        Component {
            id: systemListViewComponent
            DropAreaListView {
                id: systemListView
                objectName: "systemListView"
                mainContentView: true
                model: systemModel
            }
        }

        Component {
            id: systemGridViewComponent
            DropAreaGridView {
                id: systemGridView
                objectName: "systemGridView"
                focus: true
                model: systemModel
            }
        }
   
        onPreferredFavoritesViewComponentChanged: {
            if (root.sideBarItem != null && root.sideBarItem.currentIndex === 0) {
                stackView.replace(stackView.preferredFavoritesViewComponent)
            }
        }
        onPreferredAppsViewComponentChanged: {
            if (root.sideBarItem != null && root.sideBarItem.currentIndex >= 1) {
                stackView.replace(stackView.preferredAppsViewComponent)
            }
        }
        onPreferredSystemViewComponentChanged: {
            if (root.sideBarItem != null && root.sideBarItem.currentIndex >= root.sideBarItem.count - 1 ) {
                stackView.replace(stackView.preferredSystemViewComponent)
            }
        }
        
        
        Connections {
            target: root.sideBarItem
            function onCurrentIndexChanged() {
                // Only update row index if the condition is met.
                // The 0 index modelForRow isn't supposed to be used. That's just how it works.
                if (root.sideBarItem.currentIndex >= 0) {
                    appsModelRow = root.sideBarItem.currentIndex
                }
                if (plasmoid.configuration.showFavoritesCategory == true){
                 
                    if (root.sideBarItem.currentIndex === 0
                        && stackView.currentItem.objectName !== stackView.preferredFavoritesViewObjectName) { //I know...
                        stackView.replace(stackView.preferredFavoritesViewComponent)
                    }else if (root.sideBarItem.currentIndex >= 1
                        && stackView.currentItem.objectName !== stackView.preferredAppsViewObjectName) {
                       stackView.replace(stackView.preferredAppsViewComponent)
                    } 
                }else{
                       stackView.replace(stackView.preferredAppsViewComponent)
                }
                
                if (plasmoid.configuration.showSystemCategory == true 
                    && root.sideBarItem.currentIndex >= root.sideBarItem.count - 1
                    && stackView.currentItem.objectName !== stackView.preferredSystemViewObjectName) {
                      stackView.replace(stackView.preferredSystemViewComponent)
                    }  
            }
        } 
        Connections {
            target: plasmoid
            function onExpandedChanged() {
                if (plasmoid.expanded) {
                    plasmoid.rootItem.contentArea.currentItem.forceActiveFocus()
                }
            }
        }
    }
    // Page doesn't get destroyed when deactivated, so the binding uses
    // StackView.status and visible. This way the bindings are reset when
    // Page is Activated again.
    Binding {
        target: plasmoid.rootItem
        property: "sideBar"
        value: root.sideBarItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: plasmoid.rootItem
        property: "contentArea"
        value: root.contentAreaItem.currentItem // NOT just root.contentAreaItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }

}
        
