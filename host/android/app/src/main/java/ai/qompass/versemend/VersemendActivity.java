package ai.qompass.versemend;

import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import com.google.androidgamesdk.GameActivity;

// VersemendActivity — GameActivity subclass carrying the R1 fix
// (D-861 remainder, D-938).
//
// Stock GameActivity reports EditorInfo.inputType = TYPE_CLASS_TEXT
// with imeOptions action DONE for the games text field. In the code
// editor that means the soft keyboards Enter key fires
// IME_ACTION_DONE instead of inserting a newline, and the keyboard
// offers autocorrect while typing Lua. android-activity 0.6 exposes
// no Rust API to change either flag, so the flags are set here, on
// the Java side, by adjusting the EditorInfo that super fills in
// before the framework hands it to the IME:
//   - TYPE_TEXT_FLAG_MULTI_LINE:   Enter inserts a newline.
//   - TYPE_TEXT_FLAG_NO_SUGGESTIONS: no autocorrect in the code field.
//   - the imeOptions action bits are cleared to IME_ACTION_NONE so
//     no editor action contradicts the multi-line flag; every other
//     imeOptions bit super set (e.g. NO_EXTRACT_UI) is preserved.
// Everything else — lifecycle, native library loading, the state the
// Rust IME bridge polls — is stock GameActivity behaviour.
public class VersemendActivity extends GameActivity {

    @Override
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        InputConnection connection = super.onCreateInputConnection(outAttrs);
        if (connection != null) {
            outAttrs.inputType |= EditorInfo.TYPE_TEXT_FLAG_MULTI_LINE
                    | EditorInfo.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
            outAttrs.imeOptions = (outAttrs.imeOptions & ~EditorInfo.IME_MASK_ACTION)
                    | EditorInfo.IME_ACTION_NONE;
        }
        return connection;
    }
}
