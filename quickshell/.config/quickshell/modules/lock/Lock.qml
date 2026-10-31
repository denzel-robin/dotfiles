import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.services

// Session lock. Authenticates with your login password through PAM
// (/etc/pam.d/login — the same stack hyprlock uses).
Scope {
    id: root

    property string password: ""
    property bool busy: false
    property string error: ""
    property int fails: 0   // bumps on every failure, used to trigger the shake

    function submit(): void {
        if (busy || password === "")
            return;
        busy = true;
        error = "";
        pam.start();
    }

    PamContext {
        id: pam

        config: "login"

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
            else if (messageIsError)
                root.error = message;
        }

        onCompleted: result => {
            root.busy = false;
            root.password = "";
            if (result === PamResult.Success) {
                root.error = "";
                LockState.locked = false;
            } else {
                if (result === PamResult.MaxTries)
                    root.error = "Too many attempts — try again in a few minutes";
                else if (!root.error)
                    root.error = "Wrong password";
                root.fails++;
            }
        }

        onError: {
            root.busy = false;
            root.password = "";
            root.error = "Couldn't check the password";
            root.fails++;
        }
    }

    WlSessionLock {
        locked: LockState.locked

        WlSessionLockSurface {
            color: "black"

            LockSurface {
                anchors.fill: parent
                lock: root
            }
        }
    }
}
