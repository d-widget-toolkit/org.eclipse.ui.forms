/*******************************************************************************
 * Copyright (c) 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.ui.internal.forms.widgets.FormFonts;


import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontData;
import org.eclipse.swt.widgets.Display;

import java.lang.all;
import java.util.HashMap;
import java.util.Set;

public class FormFonts {

    private static FormFonts instance;

    public static FormFonts getInstance() {
        if (instance is null)
            instance = new FormFonts();
        return instance;
    }

    private HashMap fonts;
    private HashMap ids;

    private this() {
    }

    private class FontIdentifier {
        private Display fDisplay;
        private Font fFont;

        this (Display display, Font font) {
            fDisplay = display;
            fFont = font;
        }

        public bool equals(Object obj) {
            if (auto id = cast(FontIdentifier)obj ) {
                return id.fDisplay.opEquals(fDisplay) && id.fFont.opEquals(fFont);
            }
            return false;
        }

        public override hash_t toHash() {
            return fDisplay.toHash() * 7 + fFont.toHash();
        }
    }

    private class FontReference {
        private Font fFont;
        private int fCount;

        public this(Font font) {
            fFont = font;
            fCount = 1;
        }

        public Font getFont() {
            return fFont;
        }
        // returns a bool indicating if all clients of this font are finished
        // a true result indicates the underlying image should be disposed
        public bool decCount() {
            return --fCount is 0;
        }
        public void incCount() {
            fCount++;
        }
    }

    public Font getBoldFont(Display display, Font font) {
        checkHashMaps();
        FontIdentifier fid = new FontIdentifier(display, font);
        FontReference result = cast(FontReference) fonts.get(fid);
        if (result !is null && !result.getFont().isDisposed()) {
            result.incCount();
            return result.getFont();
        }
        Font boldFont = createBoldFont(display, font);
        fonts.put(fid, new FontReference(boldFont));
        ids.put(boldFont, fid);
        return boldFont;
    }

    public bool markFinished(Font boldFont) {
        checkHashMaps();
        FontIdentifier id = cast(FontIdentifier)ids.get(boldFont);
        if (id !is null) {
            FontReference ref_ = cast(FontReference) fonts.get(id);
            if (ref_ !is null) {
                if (ref_.decCount()) {
                    fonts.remove(id);
                    ids.remove(ref_.getFont());
                    ref_.getFont().dispose();
                    validateHashMaps();
                }
                return true;
            }
        }
        // if the image was not found, dispose of it for the caller
        boldFont.dispose();
        return false;
    }

    private Font createBoldFont(Display display, Font regularFont) {
        FontData[] fontDatas = regularFont.getFontData();
        for (int i = 0; i < fontDatas.length; i++) {
            fontDatas[i].setStyle(fontDatas[i].getStyle() | SWT.BOLD);
        }
        return new Font(display, fontDatas);
    }

    private void checkHashMaps() {
        if (fonts is null)
            fonts = new HashMap();
        if (ids is null)
            ids = new HashMap();
    }

    private void validateHashMaps() {
        if (fonts.size() is 0)
            fonts = null;
        if (ids.size() is 0)
            ids = null;
    }
}
