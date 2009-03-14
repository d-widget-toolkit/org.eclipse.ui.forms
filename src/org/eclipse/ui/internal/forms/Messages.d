/*******************************************************************************
 * Copyright (c) 2006, 2007 IBM Corporation and others.
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
module org.eclipse.ui.internal.forms.Messages;

import java.lang.all;

public class Messages /*extends NLS*/ {
    private static const String BUNDLE_NAME = "org.eclipse.ui.internal.forms.Messages"; //$NON-NLS-1$

//     private const() {
//     }

//     static {
        // initialize resource bundle
//         NLS.initializeMessages(BUNDLE_NAME, Messages.class);
//     }

    public static String FormDialog_defaultTitle;
    public static String FormText_copy;
    public static String Form_tooltip_minimize;
    public static String Form_tooltip_restore;
    /*
     * Message manager
     */
    public static String MessageManager_sMessageSummary;
    public static String MessageManager_sWarningSummary;
    public static String MessageManager_sErrorSummary;
    public static String MessageManager_pMessageSummary;
    public static String MessageManager_pWarningSummary;
    public static String MessageManager_pErrorSummary;
    public static String ToggleHyperlink_accessibleColumn;
    public static String ToggleHyperlink_accessibleName;
    public static String bind(String string, String[] strings) {
        // TODO Auto-generated method stub
        return null;
    }
}
