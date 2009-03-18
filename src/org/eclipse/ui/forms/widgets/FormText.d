/*******************************************************************************
 * Copyright (c) 2000, 2007 IBM Corporation and others.
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
module org.eclipse.ui.forms.widgets.FormText;

import org.eclipse.ui.forms.widgets.ILayoutExtension;
import org.eclipse.ui.forms.widgets.Form;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.accessibility.ACC;
import org.eclipse.swt.accessibility.Accessible;
import org.eclipse.swt.accessibility.AccessibleAdapter;
import org.eclipse.swt.accessibility.AccessibleControlAdapter;
import org.eclipse.swt.accessibility.AccessibleControlEvent;
import org.eclipse.swt.accessibility.AccessibleEvent;
import org.eclipse.swt.custom.ScrolledComposite;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.TextTransfer;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.FocusListener;
import org.eclipse.swt.events.MenuEvent;
import org.eclipse.swt.events.MenuListener;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.MouseMoveListener;
import org.eclipse.swt.events.MouseTrackListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontMetrics;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Layout;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.TypedListener;
import org.eclipse.core.runtime.ListenerList;
import org.eclipse.ui.forms.HyperlinkSettings;
import org.eclipse.ui.forms.events.HyperlinkEvent;
import org.eclipse.ui.forms.events.IHyperlinkListener;
import org.eclipse.ui.internal.forms.Messages;
import org.eclipse.ui.internal.forms.widgets.ControlSegment;
import org.eclipse.ui.internal.forms.widgets.FormFonts;
import org.eclipse.ui.internal.forms.widgets.FormTextModel;
import org.eclipse.ui.internal.forms.widgets.FormUtil;
import org.eclipse.ui.internal.forms.widgets.IFocusSelectable;
import org.eclipse.ui.internal.forms.widgets.IHyperlinkSegment;
import org.eclipse.ui.internal.forms.widgets.ImageSegment;
import org.eclipse.ui.internal.forms.widgets.Locator;
import org.eclipse.ui.internal.forms.widgets.Paragraph;
import org.eclipse.ui.internal.forms.widgets.ParagraphSegment;
import org.eclipse.ui.internal.forms.widgets.SelectionData;
import org.eclipse.ui.internal.forms.widgets.TextSegment;

import java.lang.all;
import java.util.Hashtable;
import java.util.Enumeration;
import java.util.ArrayList;
import java.util.Set;
import java.io.InputStream;

/**
 * This class is a read-only text control that is capable of rendering wrapped
 * text. Text can be rendered as-is or by parsing the formatting XML tags.
 * Independently, words that start with http:// can be converted into hyperlinks
 * on the fly.
 * <p>
 * When configured to use formatting XML, the control requires the root element
 * <code>form</code> to be used. The following tags can be children of the
 * <code>form</code> element:
 * </p>
 * <ul>
 * <li><b>p </b>- for defining paragraphs. The following attributes are
 * allowed:
 * <ul>
 * <li><b>vspace </b>- if set to 'false', no vertical space will be added
 * (default is 'true')</li>
 * </ul>
 * </li>
 * <li><b>li </b>- for defining list items. The following attributes are
 * allowed:
 * <ul>
 * <li><b>vspace </b>- the same as with the <b>p </b> tag</li>
 * <li><b>style </b>- could be 'bullet' (default), 'text' and 'image'</li>
 * <li><b>value </b>- not used for 'bullet'. For text, it is the value of the
 * text that is rendered as a bullet. For image, it is the href of the image to
 * be rendered as a bullet.</li>
 * <li><b>indent </b>- the number of pixels to indent the text in the list item
 * </li>
 * <li><b>bindent </b>- the number of pixels to indent the bullet itself</li>
 * </ul>
 * </li>
 * </ul>
 * <p>
 * Text in paragraphs and list items will be wrapped according to the width of
 * the control. The following tags can appear as children of either <b>p </b> or
 * <b>li </b> elements:
 * <ul>
 * <li><b>img </b>- to render an image. Element accepts attribute 'href' that
 * is a key to the <code>Image</code> set using 'setImage' method. Vertical
 * position of image relative to surrounding text is optionally controlled by
 * the attribute <b>align</b> that can have values <b>top</b>, <b>middle</b>
 * and <b>bottom</b></li>
 * <li><b>a </b>- to render a hyperlink. Element accepts attribute 'href' that
 * will be provided to the hyperlink listeners via HyperlinkEvent object. The
 * element also accepts 'nowrap' attribute (default is false). When set to
 * 'true', the hyperlink will not be wrapped. Hyperlinks automatically created
 * when 'http://' is encountered in text are not wrapped.</li>
 * <li><b>b </b>- the enclosed text will use bold font.</li>
 * <li><b>br </b>- forced line break (no attributes).</li>
 * <li><b>span </b>- the enclosed text will have the color and font specified
 * in the element attributes. Color is provided using 'color' attribute and is a
 * key to the Color object set by 'setColor' method. Font is provided using
 * 'font' attribute and is a key to the Font object set by 'setFont' method. As with
 * hyperlinks, it is possible to block wrapping by setting 'nowrap' to true
 * (false by default).
 * </li>
 * <li><b>control (new in 3.1)</b> - to place a control that is a child of the
 * text control. Element accepts attribute 'href' that is a key to the Control
 * object set using 'setControl' method. Optionally, attribute 'fill' can be set
 * to <code>true</code> to make the control fill the entire width of the text.
 * Form text is not responsible for creating or disposing controls, it only
 * places them relative to the surrounding text. Similar to <b>img</b>,
 * vertical position of the control can be set using the <b>align</b>
 * attribute. In addition, <b>width</b> and <b>height</b> attributes can
 * be used to force the dimensions of the control. If not used,
 * the preferred control size will be used.
 * </ul>
 * <p>
 * None of the elements can nest. For example, you cannot have <b>b </b> inside
 * a <b>span </b>. This was done to keep everything simple and transparent.
 * Since 3.1, an exception to this rule has been added to support nesting images
 * and text inside the hyperlink tag (<b>a</b>). Image enclosed in the
 * hyperlink tag acts as a hyperlink, can be clicked on and can accept and
 * render selection focus. When both text and image is enclosed, selection and
 * rendering will affect both as a single hyperlink.
 * </p>
 * <p>
 * Since 3.1, it is possible to select text. Text selection can be
 * programmatically accessed and also copied to clipboard. Non-textual objects
 * (images, controls etc.) in the selection range are ignored.
 * <p>
 * Care should be taken when using this control. Form text is not an HTML
 * browser and should not be treated as such. If you need complex formatting
 * capabilities, use Browser widget. If you need editing capabilities and
 * font/color styles of text segments is all you need, use StyleText widget.
 * Finally, if all you need is to wrap text, use SWT Label widget and create it
 * with SWT.WRAP style.
 *
 * @see FormToolkit
 * @see TableWrapLayout
 * @since 3.0
 */
public class FormText : Canvas {
    /**
     * The object ID to be used when registering action to handle URL hyperlinks
     * (those that should result in opening the web browser). Value is
     * "urlHandler".
     */
    public static const String URL_HANDLER_ID = "urlHandler"; //$NON-NLS-1$

    /**
     * Value of the horizontal margin (default is 0).
     */
    public int marginWidth = 0;

    /**
     * Value of tue vertical margin (default is 1).
     */
    public int marginHeight = 1;

    // private fields
    private static const bool DEBUG_TEXT = false;//"true".equalsIgnoreCase(Platform.getDebugOption(FormUtil.DEBUG_TEXT));
    private static const bool DEBUG_TEXTSIZE = false;//"true".equalsIgnoreCase(Platform.getDebugOption(FormUtil.DEBUG_TEXTSIZE));

    private static const bool DEBUG_FOCUS = false;//"true".equalsIgnoreCase(Platform.getDebugOption(FormUtil.DEBUG_FOCUS));

    private bool hasFocus;

    private bool paragraphsSeparated = true;

    private FormTextModel model;

    private ListenerList listeners;

    private Hashtable resourceTable;

    private IHyperlinkSegment entered;

    private IHyperlinkSegment armed;

    private bool mouseFocus = false;

    private bool controlFocusTransfer = false;

    private bool inSelection = false;

    private SelectionData selData;

    private static const String INTERNAL_MENU = "__internal_menu__"; //$NON-NLS-1$

    private static const String CONTROL_KEY = "__segment__"; //$NON-NLS-1$

    private class FormTextLayout : Layout, ILayoutExtension {
        public this() {
        }

        public int computeMaximumWidth(Composite parent, bool changed) {
            return computeSize(parent, SWT.DEFAULT, SWT.DEFAULT, changed).x;
        }

        public int computeMinimumWidth(Composite parent, bool changed) {
            return computeSize(parent, 5, SWT.DEFAULT, true).x;
        }

        /*
         * @see Layout#computeSize(Composite, int, int, bool)
         */
        public Point computeSize(Composite composite, int wHint, int hHint,
                bool changed) {
            long start = 0;

            if (DEBUG_TEXT)
                start = System.currentTimeMillis();
            int innerWidth = wHint;
            if (innerWidth !is SWT.DEFAULT)
                innerWidth -= marginWidth * 2;
            Point textSize = computeTextSize(innerWidth);
            int textWidth = textSize.x + 2 * marginWidth;
            int textHeight = textSize.y + 2 * marginHeight;
            Point result = new Point(textWidth, textHeight);
            if (DEBUG_TEXT) {
                long stop = System.currentTimeMillis();
                getDwtLogger.info( __FILE__, __LINE__, "FormText computeSize: {}ms", (stop - start)); //$NON-NLS-1$
            }
            if (DEBUG_TEXTSIZE) {
                getDwtLogger.info( __FILE__, __LINE__, "FormText ({}), computeSize: wHint={}, result={}", model.getAccessibleText(), wHint, result); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
            }
            return result;
        }

        private Point computeTextSize(int wHint) {
            Paragraph[] paragraphs = model.getParagraphs();
            GC gc = new GC(this.outer);
            gc.setFont(getFont());
            Locator loc = new Locator();
            int width = wHint !is SWT.DEFAULT ? wHint : 0;
            FontMetrics fm = gc.getFontMetrics();
            int lineHeight = fm.getHeight();
            bool selectableInTheLastRow = false;
            for (int i = 0; i < paragraphs.length; i++) {
                Paragraph p = paragraphs[i];
                if (i > 0 && getParagraphsSeparated()
                        && p.getAddVerticalSpace())
                    loc.y += getParagraphSpacing(lineHeight);
                loc.rowHeight = 0;
                loc.indent = p.getIndent();
                loc.x = p.getIndent();
                ParagraphSegment[] segments = p.getSegments();
                if (segments.length > 0) {
                    selectableInTheLastRow = false;
                    int pwidth = 0;
                    for (int j = 0; j < segments.length; j++) {
                        ParagraphSegment segment = segments[j];
                        segment.advanceLocator(gc, wHint, loc, resourceTable,
                                false);
                        if (wHint !is SWT.DEFAULT) {
                            width = Math.max(width, loc.width);
                        } else {
                            pwidth += loc.width;
                        }
                        if (null !is cast(IFocusSelectable)segment )
                            selectableInTheLastRow = true;
                    }
                    if (wHint is SWT.DEFAULT)
                        width = Math.max(width, pwidth);
                    loc.y += loc.rowHeight;
                } else {
                    // empty new line
                    loc.y += lineHeight;
                }
            }
            gc.dispose();
            if (selectableInTheLastRow)
                loc.y += 1;
            return new Point(width, loc.y);
        }

        protected void layout(Composite composite, bool flushCache) {
            long start = 0;

            if (DEBUG_TEXT) {
                start = System.currentTimeMillis();
            }
            selData = null;
            Rectangle carea = composite.getClientArea();
            if (DEBUG_TEXTSIZE) {
                getDwtLogger.info( __FILE__, __LINE__, "FormText layout ({}), carea={}",model.getAccessibleText(),carea); //$NON-NLS-1$ //$NON-NLS-2$
            }
            GC gc = new GC(composite);
            gc.setFont(getFont());
            ensureBoldFontPresent(getFont());
            gc.setForeground(getForeground());
            gc.setBackground(getBackground());

            Locator loc = new Locator();
            loc.marginWidth = marginWidth;
            loc.marginHeight = marginHeight;
            loc.x = marginWidth;
            loc.y = marginHeight;
            FontMetrics fm = gc.getFontMetrics();
            int lineHeight = fm.getHeight();

            Paragraph[] paragraphs = model.getParagraphs();
            IHyperlinkSegment selectedLink = getSelectedLink();
            for (int i = 0; i < paragraphs.length; i++) {
                Paragraph p = paragraphs[i];
                if (i > 0 && paragraphsSeparated && p.getAddVerticalSpace())
                    loc.y += getParagraphSpacing(lineHeight);
                loc.indent = p.getIndent();
                loc.resetCaret();
                loc.rowHeight = 0;
                p.layout(gc, carea.width, loc, lineHeight, resourceTable,
                        selectedLink);
            }
            gc.dispose();
            if (DEBUG_TEXT) {
                long stop = System.currentTimeMillis();
                getDwtLogger.info( __FILE__, __LINE__, "FormText.layout: {}ms", (stop - start)); //$NON-NLS-1$ //$NON-NLS-2$
            }
        }
    }

    /**
     * Contructs a new form text widget in the provided parent and using the
     * styles.
     *
     * @param parent
     *            form text parent control
     * @param style
     *            the widget style
     */
    public this(Composite parent, int style) {
        resourceTable = new Hashtable();
        super(parent, SWT.NO_BACKGROUND | SWT.WRAP | style);
        setLayout(new FormTextLayout());
        model = new FormTextModel();
        addDisposeListener(new class DisposeListener {
            public void widgetDisposed(DisposeEvent e) {
                model.dispose();
                disposeResourceTable(true);
            }
        });
        addPaintListener(new class PaintListener {
            public void paintControl(PaintEvent e) {
                paint(e);
            }
        });
        addListener(SWT.KeyDown, new class Listener {
            public void handleEvent(Event e) {
                if (e.character is '\r') {
                    activateSelectedLink();
                    return;
                }
            }
        });
        addListener(SWT.Traverse, new class Listener {
            public void handleEvent(Event e) {
                if (DEBUG_FOCUS)
                    getDwtLogger.info( __FILE__, __LINE__, "Traversal: {}", e); //$NON-NLS-1$
                switch (e.detail) {
                case SWT.TRAVERSE_PAGE_NEXT:
                case SWT.TRAVERSE_PAGE_PREVIOUS:
                case SWT.TRAVERSE_ARROW_NEXT:
                case SWT.TRAVERSE_ARROW_PREVIOUS:
                    e.doit = false;
                    return;
                default:
                }
                if (!model.hasFocusSegments()) {
                    e.doit = true;
                    return;
                }
                if (e.detail is SWT.TRAVERSE_TAB_NEXT)
                    e.doit = advance(true);
                else if (e.detail is SWT.TRAVERSE_TAB_PREVIOUS)
                    e.doit = advance(false);
                else if (e.detail !is SWT.TRAVERSE_RETURN)
                    e.doit = true;
            }
        });
        addFocusListener(new class FocusListener {
            public void focusGained(FocusEvent e) {
                if (!hasFocus) {
                    hasFocus = true;
                    if (DEBUG_FOCUS) {
                        getDwtLogger.info( __FILE__, __LINE__, "FormText: focus gained"); //$NON-NLS-1$
                    }
                    if (!mouseFocus && !controlFocusTransfer) {
                        handleFocusChange();
                    }
                }
            }

            public void focusLost(FocusEvent e) {
                if (DEBUG_FOCUS) {
                    getDwtLogger.info( __FILE__, __LINE__, "FormText: focus lost"); //$NON-NLS-1$
                }
                if (hasFocus) {
                    hasFocus = false;
                    if (!controlFocusTransfer)
                        handleFocusChange();
                }
            }
        });
        addMouseListener(new class MouseListener {
            public void mouseDoubleClick(MouseEvent e) {
            }

            public void mouseDown(MouseEvent e) {
                // select a link
                handleMouseClick(e, true);
            }

            public void mouseUp(MouseEvent e) {
                // activate a link
                handleMouseClick(e, false);
            }
        });
        addMouseTrackListener(new class MouseTrackListener {
            public void mouseEnter(MouseEvent e) {
                handleMouseMove(e);
            }

            public void mouseExit(MouseEvent e) {
                if (entered !is null) {
                    exitLink(entered, e.stateMask);
                    paintLinkHover(entered, false);
                    entered = null;
                    setCursor(null);
                }
            }

            public void mouseHover(MouseEvent e) {
                handleMouseHover(e);
            }
        });
        addMouseMoveListener(new class MouseMoveListener {
            public void mouseMove(MouseEvent e) {
                handleMouseMove(e);
            }
        });
        initAccessible();
        ensureBoldFontPresent(getFont());
        createMenu();
        // we will handle traversal of controls, if any
        setTabList(cast(Control[])null);
    }

    /**
     * Test for focus.
     *
     * @return <samp>true </samp> if the widget has focus.
     */
    public bool getFocus() {
        return hasFocus;
    }

    /**
     * Test if the widget is currently processing the text it is about to
     * render.
     *
     * @return <samp>true </samp> if the widget is still loading the text,
     *         <samp>false </samp> otherwise.
     * @deprecated not used any more - returns <code>false</code>
     */
    public bool isLoading() {
        return false;
    }

    /**
     * Returns the text that will be shown in the control while the real content
     * is loading.
     *
     * @return loading text message
     * @deprecated loading text is not used since 3.1
     */
    public String getLoadingText() {
        return null;
    }

    /**
     * Sets the text that will be shown in the control while the real content is
     * loading. This is significant when content to render is loaded from the
     * input stream that was created from a remote URL, and the time to load the
     * entire content is nontrivial.
     *
     * @param loadingText
     *            loading text message
     * @deprecated use setText(loadingText, false, false);
     */
    public void setLoadingText(String loadingText) {
        setText(loadingText, false, false);
    }

    /**
     * If paragraphs are separated, spacing will be added between them.
     * Otherwise, new paragraphs will simply start on a new line with no
     * spacing.
     *
     * @param value
     *            <samp>true </samp> if paragraphs are separated, </samp> false
     *            </samp> otherwise.
     */
    public void setParagraphsSeparated(bool value) {
        paragraphsSeparated = value;
    }

    /**
     * Tests if there is some inter-paragraph spacing.
     *
     * @return <samp>true </samp> if paragraphs are separated, <samp>false
     *         </samp> otherwise.
     */
    public bool getParagraphsSeparated() {
        return paragraphsSeparated;
    }

    /**
     * Registers the image referenced by the provided key.
     * <p>
     * For <samp>img </samp> tags, an object of a type <samp>Image </samp> must
     * be registered using the key equivalent to the value of the <samp>href
     * </samp> attribute used in the tag.
     *
     * @param key
     *            unique key that matches the value of the <samp>href </samp>
     *            attribute.
     * @param image
     *            an object of a type <samp>Image </samp>.
     */
    public void setImage(String key, Image image) {
        resourceTable.put("i." ~ key, image); //$NON-NLS-1$
    }

    /**
     * Registers the color referenced by the provided key.
     * <p>
     * For <samp>span </samp> tags, an object of a type <samp>Color </samp> must
     * be registered using the key equivalent to the value of the <samp>color
     * </samp> attribute.
     *
     * @param key
     *            unique key that matches the value of the <samp>color </samp>
     *            attribute.
     * @param color
     *            an object of the type <samp>Color </samp> or <samp>null</samp>
     *            if the key needs to be cleared.
     */
    public void setColor(String key, Color color) {
        String fullKey = "c." ~ key; //$NON-NLS-1$
        if (color is null)
            resourceTable.remove(fullKey);
        else
            resourceTable.put(fullKey, color);
    }

    /**
     * Registers the font referenced by the provided key.
     * <p>
     * For <samp>span </samp> tags, an object of a type <samp>Font </samp> must
     * be registered using the key equivalent to the value of the <samp>font
     * </samp> attribute.
     *
     * @param key
     *            unique key that matches the value of the <samp>font </samp>
     *            attribute.
     * @param font
     *            an object of the type <samp>Font </samp> or <samp>null</samp>
     *            if the key needs to be cleared.
     */
    public void setFont(String key, Font font) {
        String fullKey = "f." ~ key; //$NON-NLS-1$
        if (font is null)
            resourceTable.remove(fullKey);
        else
            resourceTable.put(fullKey, font);
        model.clearCache(fullKey);
    }

    /**
     * Registers the control referenced by the provided key.
     * <p>
     * For <samp>control</samp> tags, an object of a type <samp>Control</samp>
     * must be registered using the key equivalent to the value of the
     * <samp>control</samp> attribute.
     *
     * @param key
     *            unique key that matches the value of the <samp>control</samp>
     *            attribute.
     * @param control
     *            an object of the type <samp>Control</samp> or <samp>null</samp>
     *            if the existing control at the specified key needs to be
     *            removed.
     * @since 3.1
     */
    public void setControl(String key, Control control) {
        String fullKey = "o." ~ key; //$NON-NLS-1$
        if (control is null)
            resourceTable.remove(fullKey);
        else
            resourceTable.put(fullKey, control);
    }

    /**
     * Sets the font to use to render the default text (text that does not have
     * special font property assigned). Bold font will be constructed from this
     * font.
     *
     * @param font
     *            the default font to use
     */
    public void setFont(Font font) {
        super.setFont(font);
        model.clearCache(null);
        Font boldFont = cast(Font) resourceTable.get(FormTextModel.BOLD_FONT_ID);
        if (boldFont !is null) {
            FormFonts.getInstance().markFinished(boldFont);
            resourceTable.remove(FormTextModel.BOLD_FONT_ID);
        }
        ensureBoldFontPresent(getFont());
    }

    /**
     * Sets the provided text. Text can be rendered as-is, or by parsing the
     * formatting tags. Optionally, sections of text starting with http:// will
     * be converted to hyperlinks.
     *
     * @param text
     *            the text to render
     * @param parseTags
     *            if <samp>true </samp>, formatting tags will be parsed.
     *            Otherwise, text will be rendered as-is.
     * @param expandURLs
     *            if <samp>true </samp>, URLs found in the untagged text will be
     *            converted into hyperlinks.
     */
    public void setText(String text, bool parseTags, bool expandURLs) {
        disposeResourceTable(false);
        entered = null;
        if (parseTags)
            model.parseTaggedText(text, expandURLs);
        else
            model.parseRegularText(text, expandURLs);
        hookControlSegmentFocus();
        layout();
        redraw();
    }

    /**
     * Sets the contents of the stream. Optionally, URLs in untagged text can be
     * converted into hyperlinks. The caller is responsible for closing the
     * stream.
     *
     * @param is
     *            stream to render
     * @param expandURLs
     *            if <samp>true </samp>, URLs found in untagged text will be
     *            converted into hyperlinks.
     */
    public void setContents(InputStream is_, bool expandURLs) {
        entered = null;
        disposeResourceTable(false);
        model.parseInputStream(is_, expandURLs);
        hookControlSegmentFocus();
        layout();
        redraw();
    }

    private void hookControlSegmentFocus() {
        Paragraph[] paragraphs = model.getParagraphs();
        if (paragraphs is null)
            return;
        Listener listener = new class Listener {
            public void handleEvent(Event e) {
                switch (e.type) {
                case SWT.FocusIn:
                    if (!controlFocusTransfer)
                        syncControlSegmentFocus(cast(Control) e.widget);
                    break;
                case SWT.Traverse:
                    if (DEBUG_FOCUS)
                        getDwtLogger.info( __FILE__, __LINE__, "Control traversal: {}", e); //$NON-NLS-1$
                    switch (e.detail) {
                    case SWT.TRAVERSE_PAGE_NEXT:
                    case SWT.TRAVERSE_PAGE_PREVIOUS:
                    case SWT.TRAVERSE_ARROW_NEXT:
                    case SWT.TRAVERSE_ARROW_PREVIOUS:
                        e.doit = false;
                        return;
                    default:
                    }
                    Control c = cast(Control) e.widget;
                    ControlSegment segment = cast(ControlSegment) c
                            .getData(CONTROL_KEY);
                    if (e.detail is SWT.TRAVERSE_TAB_NEXT)
                        e.doit = advanceControl(c, segment, true);
                    else if (e.detail is SWT.TRAVERSE_TAB_PREVIOUS)
                        e.doit = advanceControl(c, segment, false);
                    if (!e.doit)
                        e.detail = SWT.TRAVERSE_NONE;
                    break;
                default:
                }
            }
        };
        for (int i = 0; i < paragraphs.length; i++) {
            Paragraph p = paragraphs[i];
            ParagraphSegment[] segments = p.getSegments();
            for (int j = 0; j < segments.length; j++) {
                if (auto cs = cast(ControlSegment)segments[j] ) {
                    Control c = cs.getControl(resourceTable);
                    if (c !is null) {
                        if (c.getData(CONTROL_KEY) is null) {
                            // first time - hook
                            c.setData(CONTROL_KEY, cs);
                            attachTraverseListener(c, listener);
                        }
                    }
                }
            }
        }
    }

    private void attachTraverseListener(Control c, Listener listener) {
        if ( auto parent = cast(Composite) c ) {
            Control[] children = parent.getChildren();
            for (int i = 0; i < children.length; i++) {
                attachTraverseListener(children[i], listener);
            }
            if (auto canv = cast(Canvas)c ) {
                // If Canvas, the control iteself can accept
                // traverse events and should be monitored
                c.addListener(SWT.Traverse, listener);
                c.addListener(SWT.FocusIn, listener);
            }
        } else {
            c.addListener(SWT.Traverse, listener);
            c.addListener(SWT.FocusIn, listener);
        }
    }

    /**
     * If we click on the control randomly, our internal book-keeping will be
     * off. We need to update the model and mark the control segment and
     * currently selected. Hyperlink that may have had focus must also be
     * exited.
     *
     * @param control
     *            the control that got focus
     */
    private void syncControlSegmentFocus(Control control) {
        ControlSegment cs = null;

        while (control !is null) {
            cs = cast(ControlSegment) control.getData(CONTROL_KEY);
            if (cs !is null)
                break;
            control = control.getParent();
        }
        if (cs is null)
            return;
        IFocusSelectable current = model.getSelectedSegment();
        // If the model and the control match, all is well
        if (current is cs)
            return;
        IHyperlinkSegment oldLink = null;
        if (current !is null && null !is cast(IHyperlinkSegment)current ) {
            oldLink = cast(IHyperlinkSegment) current;
            exitLink(oldLink, SWT.NULL);
        }
        if (DEBUG_FOCUS)
            getDwtLogger.info( __FILE__, __LINE__, "Sync control: {}, oldLink={}", cs, oldLink); //$NON-NLS-1$ //$NON-NLS-2$
        model.select(cs);
        if (oldLink !is null)
            paintFocusTransfer(oldLink, null);
        // getAccessible().setFocus(model.getSelectedSegmentIndex());
    }

    private bool advanceControl(Control c, ControlSegment segment,
            bool next) {
        Composite parent = c.getParent();
        if (parent is this) {
            // segment-level control
            IFocusSelectable nextSegment = model.getNextFocusSegment(next);
            if (nextSegment !is null) {
                controlFocusTransfer = true;
                super.forceFocus();
                controlFocusTransfer = false;
                model.select(segment);
                return advance(next);
            }
            // nowhere to go
            return setFocusToNextSibling(this, next);
        }
        if (setFocusToNextSibling(c, next))
            return true;
        // still here - must go one level up
        segment = cast(ControlSegment) parent.getData(CONTROL_KEY);
        return advanceControl(parent, segment, next);
    }

    private bool setFocusToNextSibling(Control c, bool next) {
        Composite parent = c.getParent();
        Control[] children = parent.getTabList();
        for (int i = 0; i < children.length; i++) {
            Control child = children[i];
            if (child is c) {
                // here
                if (next) {
                    for (int j = i + 1; j < children.length; j++) {
                        Control nc = children[j];
                        if (nc.setFocus())
                            return false;
                    }
                } else {
                    for (int j = i - 1; j >= 0; j--) {
                        Control pc = children[j];
                        if (pc.setFocus())
                            return false;
                    }
                }
            }
        }
        return false;
    }

    /**
     * Controls whether whitespace inside paragraph and list items is
     * normalized. Note that the new value will not affect the current text in
     * the control, only subsequent calls to <code>setText</code> or
     * <code>setContents</code>.
     * <p>
     * If normalized:
     * <ul>
     * <li>all white space characters will be condensed into at most one when
     * between words.</li>
     * <li>new line characters will be ignored and replaced with one white
     * space character</li>
     * <li>white space characters after the opening tags and before the closing
     * tags will be trimmed</li>
     *
     * @param value
     *            <code>true</code> if whitespace is normalized,
     *            <code>false</code> otherwise.
     */
    public void setWhitespaceNormalized(bool value) {
        model.setWhitespaceNormalized(value);
    }

    /**
     * Tests whether whitespace inside paragraph and list item is normalized.
     *
     * @see #setWhitespaceNormalized(bool)
     * @return <code>true</code> if whitespace is normalized,
     *         <code>false</code> otherwise.
     */
    public bool isWhitespaceNormalized() {
        return model.isWhitespaceNormalized();
    }

    /**
     * Disposes the internal menu if created and sets the menu provided as a
     * parameter.
     *
     * @param menu
     *            the menu to associate with this text control
     */
    public void setMenu(Menu menu) {
        Menu currentMenu = super.getMenu();
        if (currentMenu !is null && INTERNAL_MENU.equals(stringcast(currentMenu.getData()))) {
            // internal menu set
            if (menu !is null) {
                currentMenu.dispose();
                super.setMenu(menu);
            }
        } else
            super.setMenu(menu);
    }

    private void createMenu() {
        Menu menu = new Menu(this);
        final MenuItem copyItem = new MenuItem(menu, SWT.PUSH);
        copyItem.setText(Messages.FormText_copy);

        SelectionListener listener = new class SelectionAdapter {
            public void widgetSelected(SelectionEvent e) {
                if (e.widget is copyItem) {
                    copy();
                }
            }
        };
        copyItem.addSelectionListener(listener);
        menu.addMenuListener(new class MenuListener {
            public void menuShown(MenuEvent e) {
                copyItem.setEnabled(canCopy());
            }

            public void menuHidden(MenuEvent e) {
            }
        });
        menu.setData(stringcast(INTERNAL_MENU));
        super.setMenu(menu);
    }

    /**
     * Returns the hyperlink settings that are in effect for this control.
     *
     * @return current hyperlinks settings
     */
    public HyperlinkSettings getHyperlinkSettings() {
        return model.getHyperlinkSettings();
    }

    /**
     * Sets the hyperlink settings to be used for this control. Settings will
     * affect things like hyperlink color, rendering style, cursor etc.
     *
     * @param settings
     *            hyperlink settings for this control
     */
    public void setHyperlinkSettings(HyperlinkSettings settings) {
        model.setHyperlinkSettings(settings);
    }

    /**
     * Adds a listener that will handle hyperlink events.
     *
     * @param listener
     *            the listener to add
     */
    public void addHyperlinkListener(IHyperlinkListener listener) {
        if (listeners is null)
            listeners = new ListenerList();
        listeners.add(cast(Object)listener);
    }

    /**
     * Removes the hyperlink listener.
     *
     * @param listener
     *            the listener to remove
     */
    public void removeHyperlinkListener(IHyperlinkListener listener) {
        if (listeners is null)
            return;
        listeners.remove(cast(Object)listener);
    }

    /**
     * Adds a selection listener. A Selection event is sent by the widget when
     * the selection has changed.
     * <p>
     * <code>widgetDefaultSelected</code> is not called for FormText.
     * </p>
     *
     * @param listener
     *            the listener
     * @exception SWTException
     *                <ul>
     *                <li>ERROR_WIDGET_DISPOSED - if the receiver has been
     *                disposed</li>
     *                <li>ERROR_THREAD_INVALID_ACCESS - if not called from the
     *                thread that created the receiver</li>
     *                </ul>
     * @exception IllegalArgumentException
     *                <ul>
     *                <li>ERROR_NULL_ARGUMENT when listener is null</li>
     *                </ul>
     * @since 3.1
     */
    public void addSelectionListener(SelectionListener listener) {
        checkWidget();
        if (listener is null) {
            SWT.error(SWT.ERROR_NULL_ARGUMENT);
        }
        TypedListener typedListener = new TypedListener(listener);
        addListener(SWT.Selection, typedListener);
    }

    /**
     * Removes the specified selection listener.
     * <p>
     *
     * @param listener
     *            the listener
     * @exception SWTException
     *                <ul>
     *                <li>ERROR_WIDGET_DISPOSED - if the receiver has been
     *                disposed</li>
     *                <li>ERROR_THREAD_INVALID_ACCESS - if not called from the
     *                thread that created the receiver</li>
     *                </ul>
     * @exception IllegalArgumentException
     *                <ul>
     *                <li>ERROR_NULL_ARGUMENT when listener is null</li>
     *                </ul>
     * @since 3.1
     */
    public void removeSelectionListener(SelectionListener listener) {
        checkWidget();
        if (listener is null) {
            SWT.error(SWT.ERROR_NULL_ARGUMENT);
        }
        removeListener(SWT.Selection, listener);
    }

    /**
     * Returns the selected text.
     * <p>
     *
     * @return selected text, or an empty String if there is no selection.
     * @exception SWTException
     *                <ul>
     *                <li>ERROR_WIDGET_DISPOSED - if the receiver has been
     *                disposed</li>
     *                <li>ERROR_THREAD_INVALID_ACCESS - if not called from the
     *                thread that created the receiver</li>
     *                </ul>
     * @since 3.1
     */

    public String getSelectionText() {
        checkWidget();
        if (selData !is null)
            return selData.getSelectionText();
        return ""; //$NON-NLS-1$
    }

    /**
     * Tests if the text is selected and can be copied into the clipboard.
     *
     * @return <code>true</code> if the selected text can be copied into the
     *         clipboard, <code>false</code> otherwise.
     * @since 3.1
     */
    public bool canCopy() {
        return selData !is null && selData.canCopy();
    }

    /**
     * Copies the selected text into the clipboard. Does nothing if no text is
     * selected or the text cannot be copied for any other reason.
     *
     * @since 3.1
     */

    public void copy() {
        if (!canCopy())
            return;
        Clipboard clipboard = new Clipboard(getDisplay());
        Object[] o = [ stringcast(getSelectionText()) ];
        Transfer[] t = [ TextTransfer.getInstance() ];
        clipboard.setContents(o, t);
        clipboard.dispose();
    }

    /**
     * Returns the reference of the hyperlink that currently has keyboard focus,
     * or <code>null</code> if there are no hyperlinks in the receiver or no
     * hyperlink has focus at the moment.
     *
     * @return href of the selected hyperlink or <code>null</code> if none
     *         selected.
     * @since 3.1
     */
    public Object getSelectedLinkHref() {
        IHyperlinkSegment link = getSelectedLink();
        return link !is null ? stringcast(link.getHref()) : null;
    }

    /**
     * Returns the text of the hyperlink that currently has keyboard focus, or
     * <code>null</code> if there are no hyperlinks in the receiver or no
     * hyperlink has focus at the moment.
     *
     * @return text of the selected hyperlink or <code>null</code> if none
     *         selected.
     * @since 3.1
     */
    public String getSelectedLinkText() {
        IHyperlinkSegment link = getSelectedLink();
        return link !is null ? link.getText() : null;
    }

    private IHyperlinkSegment getSelectedLink() {
        IFocusSelectable segment = model.getSelectedSegment();
        if (segment !is null && null !is cast(IHyperlinkSegment)segment )
            return cast(IHyperlinkSegment) segment;
        return null;
    }

    private void initAccessible() {
        Accessible accessible = getAccessible();
        accessible.addAccessibleListener(new class AccessibleAdapter {
            public void getName(AccessibleEvent e) {
                if (e.childID is ACC.CHILDID_SELF)
                    e.result = model.getAccessibleText();
                else {
                    int linkCount = model.getHyperlinkCount();
                    if (e.childID >= 0 && e.childID < linkCount) {
                        IHyperlinkSegment link = model.getHyperlink(e.childID);
                        e.result = link.getText();
                    }
                }
            }

            public void getHelp(AccessibleEvent e) {
                e.result = getToolTipText();
                int linkCount = model.getHyperlinkCount();
                if (e.result is null && e.childID >= 0 && e.childID < linkCount) {
                    IHyperlinkSegment link = model.getHyperlink(e.childID);
                    e.result = link.getText();
                }
            }
        });
        accessible.addAccessibleControlListener(new class AccessibleControlAdapter {
            public void getChildAtPoint(AccessibleControlEvent e) {
                Point pt = toControl(new Point(e.x, e.y));
                IHyperlinkSegment link = model.findHyperlinkAt(pt.x, pt.y);
                if (link !is null)
                    e.childID = model.indexOf(link);
                else
                    e.childID = ACC.CHILDID_SELF;
            }

            public void getLocation(AccessibleControlEvent e) {
                Rectangle location = null;
                if (e.childID !is ACC.CHILDID_SELF
                        && e.childID !is ACC.CHILDID_NONE) {
                    int index = e.childID;
                    IHyperlinkSegment link = model.getHyperlink(index);
                    if (link !is null) {
                        location = link.getBounds();
                    }
                }
                if (location is null) {
                    location = getBounds();
                }
                Point pt = toDisplay(new Point(location.x, location.y));
                e.x = pt.x;
                e.y = pt.y;
                e.width = location.width;
                e.height = location.height;
            }

            public void getFocus(AccessibleControlEvent e) {
                int childID = ACC.CHILDID_NONE;

                if (model.hasFocusSegments()) {
                    int selectedIndex = model.getSelectedSegmentIndex();
                    if (selectedIndex !is -1) {
                        childID = selectedIndex;
                    }
                }
                e.childID = childID;
            }

            public void getDefaultAction (AccessibleControlEvent e) {
                if (model.getHyperlinkCount() > 0) {
                    e.result = SWT.getMessage ("SWT_Press"); //$NON-NLS-1$
                }
            }

            public void getChildCount(AccessibleControlEvent e) {
                e.detail = model.getHyperlinkCount();
            }

            public void getRole(AccessibleControlEvent e) {
                int role = 0;
                int childID = e.childID;
                int linkCount = model.getHyperlinkCount();
                if (childID is ACC.CHILDID_SELF) {
                    if (linkCount > 0) {
                        role = ACC.ROLE_LINK;
                    } else {
                        role = ACC.ROLE_TEXT;
                    }
                } else if (childID >= 0 && childID < linkCount) {
                    role = ACC.ROLE_LINK;
                }
                e.detail = role;
            }

            public void getSelection(AccessibleControlEvent e) {
                int selectedIndex = model.getSelectedSegmentIndex();
                e.childID = (selectedIndex is -1) ? ACC.CHILDID_NONE
                        : selectedIndex;
            }

            public void getState(AccessibleControlEvent e) {
                int linkCount = model.getHyperlinkCount();
                int selectedIndex = model.getSelectedSegmentIndex();
                int state = 0;
                int childID = e.childID;
                if (childID is ACC.CHILDID_SELF) {
                    state = ACC.STATE_NORMAL;
                } else if (childID >= 0 && childID < linkCount) {
                    state = ACC.STATE_SELECTABLE;
                    if (isFocusControl()) {
                        state |= ACC.STATE_FOCUSABLE;
                    }
                    if (selectedIndex is childID) {
                        state |= ACC.STATE_SELECTED;
                        if (isFocusControl()) {
                            state |= ACC.STATE_FOCUSED;
                        }
                    }
                }
                state |= ACC.STATE_READONLY;
                e.detail = state;
            }

            public void getChildren(AccessibleControlEvent e) {
                int linkCount = model.getHyperlinkCount();
                Object[] children = new Object[linkCount];
                for (int i = 0; i < linkCount; i++) {
                    children[i] = new Integer(i);
                }
                e.children = children;
            }

            public void getValue(AccessibleControlEvent e) {
                // e.result = model.getAccessibleText();
            }
        });
    }

    private void startSelection(MouseEvent e) {
        inSelection = true;
        selData = new SelectionData(e);
        redraw();
        Form form = FormUtil.getForm(this);
        if (form !is null)
            form.setSelectionText(this);
    }

    private void endSelection(MouseEvent e) {
        inSelection = false;
        if (selData !is null) {
            if (!selData.isEnclosed())
                selData = null;
            else
                computeSelection();
        }
        notifySelectionChanged();
    }

    private void computeSelection() {
        GC gc = new GC(this);
        Paragraph[] paragraphs = model.getParagraphs();
        IHyperlinkSegment selectedLink = getSelectedLink();
        if (getDisplay().getFocusControl() !is this)
            selectedLink = null;
        for (int i = 0; i < paragraphs.length; i++) {
            Paragraph p = paragraphs[i];
            if (i > 0)
                selData.markNewLine();
            p.computeSelection(gc, resourceTable, selectedLink, selData);
        }
        gc.dispose();
    }

    void clearSelection() {
        selData = null;
        if (!isDisposed()) {
            redraw();
            notifySelectionChanged();
        }
    }

    private void notifySelectionChanged() {
        Event event = new Event();
        event.widget = this;
        event.display = this.getDisplay();
        event.type = SWT.Selection;
        notifyListeners(SWT.Selection, event);
        getAccessible().selectionChanged();
    }

    private void handleDrag(MouseEvent e) {
        if (selData !is null) {
            ScrolledComposite scomp = FormUtil.getScrolledComposite(this);
            if (scomp !is null) {
                FormUtil.ensureVisible(scomp, this, e);
            }
            selData.update(e);
            redraw();
        }
    }

    private void handleMouseClick(MouseEvent e, bool down) {
        if (DEBUG_FOCUS)
            getDwtLogger.info( __FILE__, __LINE__, "FormText: mouse click({})", down ); //$NON-NLS-1$ //$NON-NLS-2$
        if (down) {
            // select a hyperlink
            mouseFocus = true;
            IHyperlinkSegment segmentUnder = model.findHyperlinkAt(e.x, e.y);
            if (segmentUnder !is null) {
                IHyperlinkSegment oldLink = getSelectedLink();
                if (getDisplay().getFocusControl() !is this) {
                    setFocus();
                }
                model.selectLink(segmentUnder);
                enterLink(segmentUnder, e.stateMask);
                paintFocusTransfer(oldLink, segmentUnder);
            }
            if (e.button is 1) {
                startSelection(e);
                armed = segmentUnder;
            }
            else {
            }
        } else {
            if (e.button is 1) {
                endSelection(e);
                IHyperlinkSegment segmentUnder = model
                        .findHyperlinkAt(e.x, e.y);
                if (segmentUnder !is null && armed is segmentUnder && selData is null) {
                    activateLink(segmentUnder, e.stateMask);
                    armed = null;
                }
            }
            mouseFocus = false;
        }
    }

    private void handleMouseHover(MouseEvent e) {
    }

    private void updateTooltipText(ParagraphSegment segment) {
        String tooltipText = null;
        if (segment !is null) {
            tooltipText = segment.getTooltipText();
        }
        String currentTooltipText = getToolTipText();

        if ((currentTooltipText !is null && tooltipText is null)
                || (currentTooltipText is null && tooltipText !is null))
            setToolTipText(tooltipText);
    }

    private void handleMouseMove(MouseEvent e) {
        if (inSelection) {
            handleDrag(e);
            return;
        }
        ParagraphSegment segmentUnder = model.findSegmentAt(e.x, e.y);
        updateTooltipText(segmentUnder);
        if (segmentUnder is null) {
            if (entered !is null) {
                exitLink(entered, e.stateMask);
                paintLinkHover(entered, false);
                entered = null;
            }
            setCursor(null);
        } else {
            if (auto linkUnder = cast(IHyperlinkSegment) segmentUnder ) {
                if (entered !is null && linkUnder !is entered) {
                    // Special case: links are so close that there are 0 pixels between.
                    // Must exit the link before entering the next one.
                    exitLink(entered, e.stateMask);
                    paintLinkHover(entered, false);
                    entered = null;
                }
                if (entered is null) {
                    entered = linkUnder;
                    enterLink(linkUnder, e.stateMask);
                    paintLinkHover(entered, true);
                    setCursor(model.getHyperlinkSettings().getHyperlinkCursor());
                }
            } else {
                if (entered !is null) {
                    exitLink(entered, e.stateMask);
                    paintLinkHover(entered, false);
                    entered = null;
                }
                if (null !is cast(TextSegment)segmentUnder )
                    setCursor(model.getHyperlinkSettings().getTextCursor());
                else
                    setCursor(null);
            }
        }
    }

    private bool advance(bool next) {
        if (DEBUG_FOCUS)
            getDwtLogger.info( __FILE__, __LINE__, "Advance: next={}", next); //$NON-NLS-1$
        IFocusSelectable current = model.getSelectedSegment();
        if (current !is null && null !is cast(IHyperlinkSegment)current )
            exitLink(cast(IHyperlinkSegment) current, SWT.NULL);
        IFocusSelectable newSegment = null;
        bool valid = false;
        // get the next segment that can accept focus. Links
        // can always accept focus but controls may not
        while (!valid) {
            if (!model.traverseFocusSelectableObjects(next))
                break;
            newSegment = model.getSelectedSegment();
            if (newSegment is null)
                break;
            valid = setControlFocus(next, newSegment);
        }
        IHyperlinkSegment newLink = null !is cast(IHyperlinkSegment)newSegment ? cast(IHyperlinkSegment) newSegment
                : null;
        if (valid)
            enterLink(newLink, SWT.NULL);
        IHyperlinkSegment oldLink = null !is cast(IHyperlinkSegment)current ? cast(IHyperlinkSegment) current
                : null;
        if (oldLink !is null || newLink !is null)
            paintFocusTransfer(oldLink, newLink);
        if (newLink !is null)
            ensureVisible(newLink);
        if (newLink !is null)
            getAccessible().setFocus(model.getSelectedSegmentIndex());
        return !valid;
    }

    private bool setControlFocus(bool next, IFocusSelectable selectable) {
        controlFocusTransfer = true;
        bool result = selectable.setFocus(resourceTable, next);
        controlFocusTransfer = false;
        return result;
    }

    private void handleFocusChange() {
        if (DEBUG_FOCUS) {
            getDwtLogger.info( __FILE__, __LINE__, "Handle focus change: hasFocus={}, mouseFocus={}", hasFocus, //$NON-NLS-1$
                    mouseFocus); //$NON-NLS-1$
        }
        if (hasFocus) {
            bool advance = true;
            if (!mouseFocus) {
                // if (model.restoreSavedLink() is false)
                bool valid = false;
                IFocusSelectable selectable = null;
                while (!valid) {
                    if (!model.traverseFocusSelectableObjects(advance))
                        break;
                    selectable = model.getSelectedSegment();
                    if (selectable is null)
                        break;
                    valid = setControlFocus(advance, selectable);
                }
                if (selectable is null)
                    setFocusToNextSibling(this, true);
                else
                    ensureVisible(selectable);
                if ( auto hls = cast(IHyperlinkSegment)selectable ) {
                    enterLink(hls, SWT.NULL);
                    paintFocusTransfer(null, hls);
                }
            }
        } else {
            paintFocusTransfer(getSelectedLink(), null);
            model.selectLink(null);
        }
    }

    private void enterLink(IHyperlinkSegment link, int stateMask) {
        if (link is null || listeners is null)
            return;
        int size = listeners.size();
        HyperlinkEvent he = new HyperlinkEvent(this, stringcast(link.getHref()), link
                .getText(), stateMask);
        Object [] listenerList = listeners.getListeners();
        for (int i = 0; i < size; i++) {
            IHyperlinkListener listener = cast(IHyperlinkListener) listenerList[i];
            listener.linkEntered(he);
        }
    }

    private void exitLink(IHyperlinkSegment link, int stateMask) {
        if (link is null || listeners is null)
            return;
        int size = listeners.size();
        HyperlinkEvent he = new HyperlinkEvent(this, stringcast(link.getHref()), link
                .getText(), stateMask);
        Object [] listenerList = listeners.getListeners();
        for (int i = 0; i < size; i++) {
            IHyperlinkListener listener = cast(IHyperlinkListener) listenerList[i];
            listener.linkExited(he);
        }
    }

    private void paintLinkHover(IHyperlinkSegment link, bool hover) {
        GC gc = new GC(this);
        HyperlinkSettings settings = getHyperlinkSettings();
        Color newFg = hover ? settings.getActiveForeground() : settings
                .getForeground();
        if (newFg !is null)
            gc.setForeground(newFg);
        gc.setBackground(getBackground());
        gc.setFont(getFont());
        bool selected = (link is getSelectedLink());
        (cast(ParagraphSegment) link).paint(gc, hover, resourceTable, selected,
                selData, null);
        gc.dispose();
    }

    private void activateSelectedLink() {
        IHyperlinkSegment link = getSelectedLink();
        if (link !is null)
            activateLink(link, SWT.NULL);
    }

    private void activateLink(IHyperlinkSegment link, int stateMask) {
        setCursor(model.getHyperlinkSettings().getBusyCursor());
        if (listeners !is null) {
            int size = listeners.size();
            HyperlinkEvent e = new HyperlinkEvent(this, stringcast(link.getHref()), link
                    .getText(), stateMask);
            Object [] listenerList = listeners.getListeners();
            for (int i = 0; i < size; i++) {
                IHyperlinkListener listener = cast(IHyperlinkListener) listenerList[i];
                listener.linkActivated(e);
            }
        }
        if (!isDisposed() && model.linkExists(link)) {
            setCursor(model.getHyperlinkSettings().getHyperlinkCursor());
        }
    }

    private void ensureBoldFontPresent(Font regularFont) {
        Font boldFont = cast(Font) resourceTable.get(FormTextModel.BOLD_FONT_ID);
        if (boldFont !is null)
            return;
        boldFont = FormFonts.getInstance().getBoldFont(getDisplay(), regularFont);
        resourceTable.put(FormTextModel.BOLD_FONT_ID, boldFont);
    }

    private void paint(PaintEvent e) {
        GC gc = e.gc;
        gc.setFont(getFont());
        ensureBoldFontPresent(getFont());
        gc.setForeground(getForeground());
        gc.setBackground(getBackground());
        repaint(gc, e.x, e.y, e.width, e.height);
    }

    private void repaint(GC gc, int x, int y, int width, int height) {
        Image textBuffer = new Image(getDisplay(), width, height);
        Color bg = getBackground();
        Color fg = getForeground();
        if (!getEnabled()) {
            bg = getDisplay().getSystemColor(SWT.COLOR_WIDGET_BACKGROUND);
            fg = getDisplay().getSystemColor(SWT.COLOR_WIDGET_NORMAL_SHADOW);
        }
        GC textGC = new GC(textBuffer, gc.getStyle());
        textGC.setForeground(fg);
        textGC.setBackground(bg);
        textGC.setFont(getFont());
        textGC.fillRectangle(0, 0, width, height);
        Rectangle repaintRegion = new Rectangle(x, y, width, height);

        Paragraph[] paragraphs = model.getParagraphs();
        IHyperlinkSegment selectedLink = getSelectedLink();
        if (getDisplay().getFocusControl() !is this)
            selectedLink = null;
        for (int i = 0; i < paragraphs.length; i++) {
            Paragraph p = paragraphs[i];
            p
                    .paint(textGC, repaintRegion, resourceTable, selectedLink,
                            selData);
        }
        textGC.dispose();
        gc.drawImage(textBuffer, x, y);
        textBuffer.dispose();
    }

    private int getParagraphSpacing(int lineHeight) {
        return lineHeight / 2;
    }

    private void paintFocusTransfer(IHyperlinkSegment oldLink,
            IHyperlinkSegment newLink) {
        GC gc = new GC(this);
        Color bg = getBackground();
        Color fg = getForeground();
        gc.setFont(getFont());
        if (oldLink !is null) {
            gc.setBackground(bg);
            gc.setForeground(fg);
            oldLink.paintFocus(gc, bg, fg, false, null);
        }
        if (newLink !is null) {
            // ensureVisible(newLink);
            gc.setBackground(bg);
            gc.setForeground(fg);
            newLink.paintFocus(gc, bg, fg, true, null);
        }
        gc.dispose();
    }

    private void ensureVisible(IFocusSelectable segment) {
        if (mouseFocus) {
            mouseFocus = false;
            return;
        }
        if (segment is null)
            return;
        Rectangle bounds = segment.getBounds();
        ScrolledComposite scomp = FormUtil.getScrolledComposite(this);
        if (scomp is null)
            return;
        Point origin = FormUtil.getControlLocation(scomp, this);
        origin.x += bounds.x;
        origin.y += bounds.y;
        FormUtil.ensureVisible(scomp, origin, new Point(bounds.width,
                bounds.height));
    }

    /**
     * Overrides the method by fully trusting the layout manager (computed width
     * or height may be larger than the provider width or height hints). Callers
     * should be prepared that the computed width is larger than the provided
     * wHint.
     *
     * @see org.eclipse.swt.widgets.Composite#computeSize(int, int, bool)
     */
    public Point computeSize(int wHint, int hHint, bool changed) {
        checkWidget();
        Point size;
        FormTextLayout layout = cast(FormTextLayout) getLayout();
        if (wHint is SWT.DEFAULT || hHint is SWT.DEFAULT) {
            size = layout.computeSize(this, wHint, hHint, changed);
        } else {
            size = new Point(wHint, hHint);
        }
        Rectangle trim = computeTrim(0, 0, size.x, size.y);
        if (DEBUG_TEXTSIZE)
            getDwtLogger.info( __FILE__, __LINE__, "FormText Computed size: {}",trim); //$NON-NLS-1$
        return new Point(trim.width, trim.height);
    }

    private void disposeResourceTable(bool disposeBoldFont) {
        if (disposeBoldFont) {
            Font boldFont = cast(Font) resourceTable
                    .get(FormTextModel.BOLD_FONT_ID);
            if (boldFont !is null) {
                FormFonts.getInstance().markFinished(boldFont);
                resourceTable.remove(FormTextModel.BOLD_FONT_ID);
            }
        }
        ArrayList imagesToRemove = new ArrayList();
        for (Enumeration enm = resourceTable.keys(); enm.hasMoreElements();) {
            String key = stringcast( enm.nextElement());
            if (key.startsWith(ImageSegment.SEL_IMAGE_PREFIX)) {
                Object obj = resourceTable.get(key);
                if (auto image = cast(Image)obj ) {
                    if (!image.isDisposed()) {
                        image.dispose();
                        imagesToRemove.add(key);
                    }
                }
            }
        }
        for (int i = 0; i < imagesToRemove.size(); i++) {
            resourceTable.remove(imagesToRemove.get(i));
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.swt.widgets.Control#setEnabled(bool)
     */
    public void setEnabled(bool enabled) {
        super.setEnabled(enabled);
        redraw();
    }

    /* (non-Javadoc)
     * @see org.eclipse.swt.widgets.Control#setFocus()
     */
    public bool setFocus() {
        FormUtil.setFocusScrollingEnabled(this, false);
        bool result = super.setFocus();
        FormUtil.setFocusScrollingEnabled(this, true);
        return result;
    }
}
