package ai.qompass.versemend;

import android.os.Bundle;
import android.view.inputmethod.EditorInfo;
import com.google.androidgamesdk.GameActivity;

// VersemendActivity — GameActivity subclass carrying the R1 fix
// (D-861 remainder, D-938).
//
// Stock GameActivity defaults its IME EditorInfo to inputType =
// TYPE_CLASS_TEXT (1) with action DONE (its lazy default in
// getImeEditorInfo(): actionId 6, imeOptions 0x02000006). In the
// code editor that makes the soft keyboards Enter key fire
// IME_ACTION_DONE instead of inserting a newline, and the keyboard
// offers autocorrect while typing Lua. android-activity 0.6 exposes
// no Rust API to change either flag.
//
// The flags live on the EditorInfo, and every write path to it —
// setImeEditorInfo, setImeEditorInfoFields, and the lazy default —
// converges on the one instance the live gametextinput
// InputConnection reads (its setEditorInfo also recomputes the text
// filters, dropping the single-line filter when MULTI_LINE is set).
// This subclass therefore routes the info through the setter once
// after onCreate, and re-applies the flags inside both setter
// overrides, so no later write can restore the stock values:
//   - TYPE_TEXT_FLAG_MULTI_LINE:     Enter inserts a newline.
//   - TYPE_TEXT_FLAG_NO_SUGGESTIONS: no autocorrect in the code field.
//   - the imeOptions action bits and actionId are set to
//     IME_ACTION_NONE so no editor action contradicts the
//     multi-line flag; every other bit (e.g. NO_EXTRACT_UI) is kept.
// Everything else — lifecycle, native library loading, the state
// the Rust IME bridge polls — is stock GameActivity behaviour.
public class VersemendActivity extends GameActivity {

    private static void applyEditorFlags(EditorInfo info) {
        if (info == null) {
            return;
        }
        info.inputType |= EditorInfo.TYPE_TEXT_FLAG_MULTI_LINE
                | EditorInfo.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
        info.imeOptions = (info.imeOptions & ~EditorInfo.IME_MASK_ACTION)
                | EditorInfo.IME_ACTION_NONE;
        info.actionId = EditorInfo.IME_ACTION_NONE;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // The surface view and its InputConnection exist now; pushing
        // the (lazily defaulted) info back through the setter makes
        // the live connection re-read it with the R1 flags applied.
        setImeEditorInfo(getImeEditorInfo());
    }

    @Override
    public void setImeEditorInfo(EditorInfo editorInfo) {
        applyEditorFlags(editorInfo);
        super.setImeEditorInfo(editorInfo);
    }

    @Override
    public void setImeEditorInfoFields(int inputType, int actionId, int imeOptions) {
        super.setImeEditorInfoFields(inputType, actionId, imeOptions);
        // Super wrote the callers raw values; re-apply the R1 flags.
        setImeEditorInfo(getImeEditorInfo());
    }
}
