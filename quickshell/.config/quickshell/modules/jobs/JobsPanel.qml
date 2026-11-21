import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// The tracker: today's routine, then every company with its status. Click a row to edit it.
Overlay {
    id: root

    name: "jobs"
    dim: false

    property string filter: "all"
    property bool editing: false
    property string editId: ""       // "" while adding a new one
    property string formStatus: "todo"
    property bool confirmDelete: false
    property bool formInvalid: false

    readonly property var rows: Jobs.view(filter, search.text)
    readonly property var filters: [{ id: "all", label: "All" }, { id: "due", label: "Follow up" }].concat(Jobs.statuses)
    readonly property real maxListHeight: height * 0.5

    onShownChanged: {
        if (!shown)
            return;
        editing = false;
        search.text = "";
        search.forceActiveFocus();
    }

    function openEditor(entry: var): void {
        const e = entry ?? {};
        editId = e.id ?? "";
        formStatus = e.status ?? "todo";
        companyField.text = e.company ?? "";
        roleField.text = e.role ?? "";
        contactField.text = e.contact ?? "";
        linkField.text = e.link ?? "";
        appliedField.text = e.applied ?? "";
        notesField.text = e.notes ?? "";
        confirmDelete = false;
        formInvalid = false;
        editing = true;
        companyField.focusInput();
    }

    function closeEditor(): void {
        editing = false;
        search.forceActiveFocus();
    }

    function saveEditor(): void {
        const date = appliedField.text.trim();
        formInvalid = !companyField.text.trim() || (date !== "" && !Jobs.validDate(date));
        if (formInvalid || !Jobs.ready)   // keep what was typed if it can't be saved
            return;
        const fields = {
            company: companyField.text,
            role: roleField.text,
            contact: contactField.text,
            link: linkField.text,
            applied: date,
            notes: notesField.text,
            status: formStatus
        };
        if (editId)
            Jobs.change(editId, fields);
        else
            Jobs.add(fields);
        closeEditor();
    }

    function statusColor(status: string): color {
        return status === "offer" ? Colors.primary
            : status === "interview" ? Colors.tertiaryContainer
            : status === "applied" ? Colors.secondaryContainer
            : Colors.surfaceContainerHighest;
    }

    function statusTextColor(status: string): color {
        return status === "offer" ? Colors.textOnPrimary
            : status === "interview" ? Colors.textOnTertiaryContainer
            : status === "applied" ? Colors.textOnSecondaryContainer
            : Colors.textOnSurfaceVariant;
    }

    component Chip: Rectangle {
        id: chip

        property string label
        property bool active: false
        signal clicked

        implicitWidth: chipText.implicitWidth + 20
        implicitHeight: 28
        radius: 14
        color: active ? Colors.primary : Colors.surfaceContainerHigh

        Behavior on color { CAnim { duration: Appearance.anim.fast } }

        StyledText {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            font.pixelSize: Appearance.font.small + 1
            font.weight: chip.active ? Font.DemiBold : Font.Normal
            color: chip.active ? Colors.textOnPrimary : Colors.textOnSurfaceVariant
        }

        StateLayer {
            tint: chip.active ? Colors.textOnPrimary : Colors.textOnSurface
            onClicked: chip.clicked()
        }
    }

    component Stat: Rectangle {
        id: stat

        property string value
        property string caption
        property real progress: -1     // -1 = no bar
        property bool checkable: false
        property bool checked: false
        signal clicked

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 64
        radius: Appearance.rounding.small
        color: checked ? Colors.primaryContainer : Colors.surfaceContainerHigh
        clip: true

        Behavior on color { CAnim { duration: Appearance.anim.fast } }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.normal
            spacing: 1

            Row {
                spacing: Appearance.spacing.small

                MaterialIcon {
                    visible: stat.checkable
                    anchors.verticalCenter: parent.verticalCenter
                    icon: stat.checked ? "check_circle" : "radio_button_unchecked"
                    fill: stat.checked ? 1 : 0
                    size: 20
                    color: stat.checked ? Colors.textOnPrimaryContainer : Colors.textOnSurfaceVariant
                }

                StyledText {
                    text: stat.value
                    font.pixelSize: Appearance.font.large + 2
                    font.weight: Font.Medium
                    color: stat.checked ? Colors.textOnPrimaryContainer : Colors.textOnSurface
                }
            }

            StyledText {
                width: parent.width
                text: stat.caption
                font.pixelSize: Appearance.font.small
                color: stat.checked ? Colors.textOnPrimaryContainer : Colors.textOnSurfaceVariant
                elide: Text.ElideRight
            }
        }

        Rectangle {
            visible: stat.progress >= 0
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width * Math.min(1, Math.max(0, stat.progress))
            height: 3
            color: Colors.primary

            Behavior on width { Anim { duration: Appearance.anim.fast } }
        }

        StateLayer {
            visible: stat.checkable
            onClicked: stat.clicked()
        }
    }

    component Field: ColumnLayout {
        id: field

        property string label
        property string hint
        property bool invalid: false
        property alias text: input.text

        function focusInput(): void {
            input.forceActiveFocus();
        }

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: 3

        StyledText {
            text: field.label
            font.pixelSize: Appearance.font.small
            color: field.invalid ? Colors.error : Colors.textOnSurfaceVariant
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Appearance.rounding.small
            color: Colors.surfaceContainerHigh
            border.width: input.activeFocus ? 2 : 1
            border.color: field.invalid ? Colors.error : input.activeFocus ? Colors.primary : Colors.alpha(Colors.outlineVariant, 0.6)

            TextInput {
                id: input

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Appearance.padding.normal
                anchors.rightMargin: Appearance.padding.normal
                activeFocusOnTab: true
                selectByMouse: true
                clip: true
                color: Colors.textOnSurface
                selectionColor: Colors.primary
                selectedTextColor: Colors.textOnPrimary
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.normal
                Keys.onReturnPressed: root.saveEditor()
                Keys.onEnterPressed: root.saveEditor()
                Keys.onEscapePressed: root.closeEditor()

                StyledText {
                    visible: !input.text
                    anchors.verticalCenter: parent.verticalCenter
                    text: field.hint
                    color: Colors.outline
                }
            }
        }
    }

    component Pill: Rectangle {
        id: pill

        property string label
        property string iconName
        property color fg: Colors.textOnSurface
        signal clicked

        implicitWidth: pillRow.implicitWidth + 22
        implicitHeight: 32
        radius: 16
        color: "transparent"

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                visible: pill.iconName !== ""
                anchors.verticalCenter: parent.verticalCenter
                icon: pill.iconName
                size: 16
                color: pill.fg
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.label
                font.pixelSize: Appearance.font.small + 1
                font.weight: Font.Medium
                color: pill.fg
            }
        }

        StateLayer {
            tint: pill.fg
            onClicked: pill.clicked()
        }
    }

    Card {
        id: card

        anchors.left: parent.left
        anchors.leftMargin: Appearance.bar.margin * 2 + Appearance.bar.islandWidth
        y: Math.max(Appearance.bar.margin, Math.min(Jobs.islandBottom || parent.height, parent.height - Appearance.bar.margin) - height)
        width: 640
        height: layout.implicitHeight + Appearance.padding.large * 2
        radius: Appearance.rounding.normal
        clip: true
        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress
        transformOrigin: Item.BottomLeft
        transform: Translate { x: (root.progress - 1) * 30 }

        Behavior on height { Anim { duration: Appearance.anim.fast; easing.bezierCurve: Appearance.anim.emphasized } }

        ColumnLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.large

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: root.editing ? (root.editId ? "Edit company" : "Add company") : "Job search"
                    font.pixelSize: Appearance.font.large
                    font.weight: Font.Medium
                }

                Pill {
                    visible: !root.editing
                    label: Jobs.hidden ? "Show on bar" : "Hide from bar"
                    iconName: Jobs.hidden ? "visibility" : "visibility_off"
                    fg: Colors.textOnSurfaceVariant
                    onClicked: {
                        const hide = !Jobs.hidden;
                        Jobs.setHidden(hide);
                        if (hide)
                            Panels.close();
                    }
                }

                Pill {
                    visible: !root.editing
                    color: Colors.primary
                    fg: Colors.textOnPrimary
                    label: "Add"
                    iconName: "add"
                    onClicked: root.openEditor(null)
                }
            }

            // Couldn't read the data file
            Rectangle {
                visible: Jobs.problem !== ""
                Layout.fillWidth: true
                implicitHeight: problemText.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.small
                color: Colors.alpha(Colors.error, 0.16)

                StyledText {
                    id: problemText
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    text: Jobs.problem
                    color: Colors.error
                    wrapMode: Text.Wrap
                }
            }

            // ── List ──
            RowLayout {
                visible: !root.editing
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                Stat {
                    value: Jobs.weekend ? Jobs.appliedToday : `${Jobs.appliedToday} / ${Jobs.dailyGoal}`
                    caption: "Applied today"
                    progress: Jobs.weekend ? -1 : Jobs.appliedToday / Jobs.dailyGoal
                }

                Stat {
                    checkable: true
                    readonly property string key: Jobs.weekend ? Jobs.weekendKey : Jobs.dsaKey
                    checked: Jobs.done[key] === true
                    value: Jobs.weekend ? "Project" : "DSA"
                    caption: Jobs.weekend ? "Improve one, or post" : "1 hour today"
                    onClicked: Jobs.tick(key)
                }

                Stat {
                    value: `${Jobs.referralsThisWeek} / ${Jobs.referralGoal}`
                    caption: "Messages this week"
                    progress: Jobs.referralsThisWeek / Jobs.referralGoal
                }

                Stat {
                    value: `${Jobs.sent} / ${Jobs.sentGoal}`
                    caption: "Sent in total"
                    progress: Jobs.sent / Jobs.sentGoal
                }
            }

            // Search
            Rectangle {
                visible: !root.editing
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 18
                color: Colors.surfaceContainerHigh

                MaterialIcon {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.padding.normal
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "search"
                    size: 18
                    color: Colors.textOnSurfaceVariant
                }

                TextInput {
                    id: search

                    anchors.left: searchIcon.right
                    anchors.right: parent.right
                    anchors.leftMargin: Appearance.spacing.normal
                    anchors.rightMargin: Appearance.padding.large
                    anchors.verticalCenter: parent.verticalCenter
                    selectByMouse: true
                    clip: true
                    color: Colors.textOnSurface
                    selectionColor: Colors.primary
                    selectedTextColor: Colors.textOnPrimary
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.normal

                    StyledText {
                        visible: !search.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search companies, roles, people, notes"
                        color: Colors.outline
                    }
                }
            }

            // Filters
            Flow {
                visible: !root.editing
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                Repeater {
                    model: root.filters

                    Chip {
                        required property var modelData
                        label: `${modelData.label} ${Jobs.count(modelData.id)}`
                        active: root.filter === modelData.id
                        onClicked: root.filter = modelData.id
                    }
                }
            }

            Flickable {
                id: list

                visible: !root.editing && root.rows.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(rowsColumn.implicitHeight, root.maxListHeight)
                clip: true
                contentHeight: rowsColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: rowsColumn

                    width: list.width
                    spacing: 2

                    Repeater {
                        model: root.rows

                        Rectangle {
                            id: row

                            required property var modelData
                            readonly property bool due: Jobs.isDue(modelData)
                            readonly property string details: {
                                const e = modelData;
                                const parts = [];
                                if (e.role)
                                    parts.push(e.role);
                                if (e.contact)
                                    parts.push(e.contact);
                                if (e.applied)
                                    parts.push(`Applied ${Jobs.shortDate(e.applied)}`);
                                if (e.followedUp)
                                    parts.push(`Followed up ${Jobs.shortDate(e.followedUp)}`);
                                return parts.join("  ·  ");
                            }

                            width: rowsColumn.width
                            implicitHeight: 52
                            radius: Appearance.rounding.small
                            color: "transparent"

                            StateLayer {
                                onClicked: root.openEditor(row.modelData)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.padding.normal
                                anchors.rightMargin: Appearance.padding.small
                                spacing: Appearance.spacing.normal

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: row.modelData.company
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: row.details !== ""
                                        text: row.details
                                        font.pixelSize: Appearance.font.small
                                        color: Colors.textOnSurfaceVariant
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    visible: row.modelData.link !== "" && row.modelData.link !== undefined
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    radius: 15
                                    color: "transparent"

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        icon: "open_in_new"
                                        size: 16
                                        color: Colors.textOnSurfaceVariant
                                    }

                                    StateLayer {
                                        onClicked: {
                                            Jobs.openLink(row.modelData.link);
                                            Panels.close();
                                        }
                                    }
                                }

                                // The next thing to do with this one
                                Pill {
                                    visible: row.due || row.modelData.status === "todo"
                                    implicitHeight: 28
                                    color: row.due ? Colors.tertiaryContainer : Colors.secondaryContainer
                                    fg: row.due ? Colors.textOnTertiaryContainer : Colors.textOnSecondaryContainer
                                    label: row.due ? "Mark followed up" : "Mark applied"
                                    onClicked: {
                                        if (row.due)
                                            Jobs.change(row.modelData.id, { followedUp: Jobs.today });
                                        else
                                            Jobs.change(row.modelData.id, { status: "applied" });
                                    }
                                }

                                Rectangle {
                                    visible: row.modelData.status !== "todo"
                                    implicitWidth: statusText.implicitWidth + 16
                                    implicitHeight: 22
                                    radius: 11
                                    color: root.statusColor(row.modelData.status)

                                    StyledText {
                                        id: statusText
                                        anchors.centerIn: parent
                                        text: Jobs.statusLabel(row.modelData.status)
                                        font.pixelSize: Appearance.font.small
                                        font.weight: Font.Medium
                                        color: root.statusTextColor(row.modelData.status)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: !root.editing && root.rows.length === 0
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.large
                Layout.bottomMargin: Appearance.spacing.large
                horizontalAlignment: Text.AlignHCenter
                text: search.text ? "No matches" : root.filter === "due" ? "No follow-ups due" : "Nothing here yet"
                color: Colors.textOnSurfaceVariant
            }

            // ── Add / edit ──
            Flow {
                visible: root.editing
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                Repeater {
                    model: Jobs.statuses

                    Chip {
                        required property var modelData
                        label: modelData.label
                        active: root.formStatus === modelData.id
                        onClicked: root.formStatus = modelData.id
                    }
                }
            }

            GridLayout {
                visible: root.editing
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Appearance.spacing.large
                rowSpacing: Appearance.spacing.normal

                Field {
                    id: companyField
                    label: "Company"
                    hint: "Required"
                    invalid: root.formInvalid && !text.trim()
                }

                Field {
                    id: roleField
                    label: "Role"
                    hint: "ML engineer"
                }

                Field {
                    id: contactField
                    label: "Who you contacted"
                    hint: "Name, for a referral or cold message"
                }

                Field {
                    id: linkField
                    label: "Link"
                    hint: "Job posting or careers page"
                }

                Field {
                    id: appliedField
                    label: "Date applied"
                    hint: root.formStatus === "todo" ? "Set when you apply" : "YYYY-MM-DD, blank for today"
                    invalid: root.formInvalid && text.trim() !== "" && !Jobs.validDate(text.trim())
                }

                Field {
                    id: notesField
                    label: "Notes"
                }
            }

            RowLayout {
                visible: root.editing
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                Pill {
                    visible: root.editId !== ""
                    color: root.confirmDelete ? Colors.error : "transparent"
                    fg: root.confirmDelete ? Colors.textOnError : Colors.error
                    label: root.confirmDelete ? "Click again to delete" : "Delete"
                    iconName: "delete"
                    onClicked: {
                        if (root.confirmDelete) {
                            Jobs.remove(root.editId);
                            root.closeEditor();
                        } else {
                            root.confirmDelete = true;
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Pill {
                    fg: Colors.textOnSurfaceVariant
                    label: "Cancel"
                    onClicked: root.closeEditor()
                }

                Pill {
                    color: Colors.primary
                    fg: Colors.textOnPrimary
                    label: "Save"
                    iconName: "check"
                    onClicked: root.saveEditor()
                }
            }
        }
    }
}
