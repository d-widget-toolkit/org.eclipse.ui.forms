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
module org.eclipse.ui.internal.forms.widgets.FormHeading;

import org.eclipse.ui.internal.forms.widgets.TitleRegion;
import org.eclipse.ui.internal.forms.widgets.FormImages;
import org.eclipse.ui.internal.forms.widgets.FormsResources;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.dnd.DragSourceListener;
import org.eclipse.swt.dnd.DropTargetListener;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.MouseMoveListener;
import org.eclipse.swt.events.MouseTrackListener;
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
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.core.runtime.Assert;
import org.eclipse.core.runtime.ListenerList;
import org.eclipse.jface.action.IMenuManager;
import org.eclipse.jface.action.IToolBarManager;
import org.eclipse.jface.action.ToolBarManager;
import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.jface.dialogs.IMessageProvider;
import org.eclipse.jface.resource.JFaceResources;
import org.eclipse.ui.forms.IFormColors;
import org.eclipse.ui.forms.IMessage;
import org.eclipse.ui.forms.events.IHyperlinkListener;
import org.eclipse.ui.forms.widgets.Hyperlink;
import org.eclipse.ui.forms.widgets.ILayoutExtension;
import org.eclipse.ui.forms.widgets.SizeCache;
import org.eclipse.ui.internal.forms.IMessageToolTipManager;
import org.eclipse.ui.internal.forms.MessageManager;

import java.lang.all;
import java.util.Hashtable;
import java.util.Set;

/**
 * Form header moved out of the form class.
 */
public class FormHeading : Canvas {
    private static const int TITLE_HMARGIN = 1;
    private static const int SPACING = 5;
    private static const int VSPACING = 5;
    private static const int HMARGIN = 6;
    private static const int VMARGIN = 1;
    private static const int CLIENT_MARGIN = 1;

    private static const int SEPARATOR = 1 << 1;
    private static const int BOTTOM_TOOLBAR = 1 << 2;
    private static const int BACKGROUND_IMAGE_TILED = 1 << 3;
    private static const int SEPARATOR_HEIGHT = 2;
    private static const int MESSAGE_AREA_LIMIT = 50;
    static IMessage[] NULL_MESSAGE_ARRAY;

    public static const String COLOR_BASE_BG = "baseBg"; //$NON-NLS-1$

    private Image backgroundImage;

    private Image gradientImage;

    Hashtable colors;

    private int flags;

    private GradientInfo gradientInfo;

    private ToolBarManager toolBarManager;

    private SizeCache toolbarCache;

    private SizeCache clientCache;

    private SizeCache messageCache;

    private TitleRegion titleRegion;

    private MessageRegion messageRegion;

    private IMessageToolTipManager messageToolTipManager;

    private Control headClient;

    private class DefaultMessageToolTipManager :
            IMessageToolTipManager {
        public void createToolTip(Control control, bool imageLabel) {
        }

        public void update() {
            String details = getMessageType() is 0 ? null : MessageManager
                    .createDetails(getChildrenMessages());
            if (messageRegion !is null)
                messageRegion.updateToolTip(details);
            if (getMessageType() > 0
                    && (details is null || details.length is 0))
                details = getMessage();
            titleRegion.updateToolTip(details);
        }
    }

    private class GradientInfo {
        Color[] gradientColors;

        int[] percents;

        bool vertical;
    }

    private class FormHeadingLayout : Layout, ILayoutExtension {
        public int computeMinimumWidth(Composite composite, bool flushCache) {
            return computeSize(composite, 5, SWT.DEFAULT, flushCache).x;
        }

        public int computeMaximumWidth(Composite composite, bool flushCache) {
            return computeSize(composite, SWT.DEFAULT, SWT.DEFAULT, flushCache).x;
        }

        public Point computeSize(Composite composite, int wHint, int hHint,
                bool flushCache) {
            return layout(composite, false, 0, 0, wHint, hHint, flushCache);
        }

        protected void layout(Composite composite, bool flushCache) {
            Rectangle rect = composite.getClientArea();
            layout(composite, true, rect.x, rect.y, rect.width, rect.height,
                    flushCache);
        }

        private Point layout(Composite composite, bool move, int x, int y,
                int width, int height, bool flushCache) {
            Point tsize = null;
            Point msize = null;
            Point tbsize = null;
            Point clsize = null;

            if (flushCache) {
                clientCache.flush();
                messageCache.flush();
                toolbarCache.flush();
            }
            if (hasToolBar()) {
                ToolBar tb = toolBarManager.getControl();
                toolbarCache.setControl(tb);
                tbsize = toolbarCache.computeSize(SWT.DEFAULT, SWT.DEFAULT);
            }
            if (headClient !is null) {
                clientCache.setControl(headClient);
                int cwhint = width;
                if (cwhint !is SWT.DEFAULT) {
                    cwhint -= HMARGIN * 2;
                    if (tbsize !is null && getToolBarAlignment() is SWT.BOTTOM)
                        cwhint -= tbsize.x + SPACING;
                }
                clsize = clientCache.computeSize(cwhint, SWT.DEFAULT);
            }
            int totalFlexWidth = width;
            int flexWidth = totalFlexWidth;
            if (totalFlexWidth !is SWT.DEFAULT) {
                totalFlexWidth -= TITLE_HMARGIN * 2;
                // complete right margin
                if (hasToolBar() && getToolBarAlignment() is SWT.TOP
                        || hasMessageRegion())
                    totalFlexWidth -= SPACING;
                // subtract tool bar
                if (hasToolBar() && getToolBarAlignment() is SWT.TOP)
                    totalFlexWidth -= tbsize.x + SPACING;
                flexWidth = totalFlexWidth;
                if (hasMessageRegion()) {
                    // remove message region spacing and divide by 2
                    flexWidth -= SPACING;
                    // flexWidth /= 2;
                }
            }
            /*
             * // compute text and message sizes tsize =
             * titleRegion.computeSize(flexWidth, SWT.DEFAULT); if (flexWidth !is
             * SWT.DEFAULT && tsize.x < flexWidth) flexWidth += flexWidth -
             * tsize.x;
             *
             * if (hasMessageRegion()) {
             * messageCache.setControl(messageRegion.getMessageControl()); msize =
             * messageCache.computeSize(flexWidth, SWT.DEFAULT); int maxWidth =
             * messageCache.computeSize(SWT.DEFAULT, SWT.DEFAULT).x; if
             * (maxWidth < msize.x) { msize.x = maxWidth; // recompute title
             * with the reclaimed width int tflexWidth = totalFlexWidth -
             * SPACING - msize.x; tsize = titleRegion.computeSize(tflexWidth,
             * SWT.DEFAULT); } }
             */
            if (!hasMessageRegion()) {
                tsize = titleRegion.computeSize(flexWidth, SWT.DEFAULT);
            } else {
                // Total flexible area in the first row is flexWidth.
                // Try natural widths of title and
                Point tsizeNatural = titleRegion.computeSize(SWT.DEFAULT,
                        SWT.DEFAULT);
                messageCache.setControl(messageRegion.getMessageControl());
                Point msizeNatural = messageCache.computeSize(SWT.DEFAULT,
                        SWT.DEFAULT);
                // try to fit all
                tsize = tsizeNatural;
                msize = msizeNatural;
                if (flexWidth !is SWT.DEFAULT) {
                    int needed = tsizeNatural.x + msizeNatural.x;
                    if (needed > flexWidth) {
                        // too big - try to limit the message
                        int mwidth = flexWidth - tsizeNatural.x;
                        if (mwidth >= MESSAGE_AREA_LIMIT) {
                            msize.x = mwidth;
                        } else {
                            // message is squeezed to the limit
                            int flex = flexWidth - MESSAGE_AREA_LIMIT;
                            tsize = titleRegion.computeSize(flex, SWT.DEFAULT);
                            msize.x = MESSAGE_AREA_LIMIT;
                        }
                    }
                }
            }

            Point size = new Point(width, height);
            if (!move) {
                // compute sizes
                int width1 = 2 * TITLE_HMARGIN;
                width1 += tsize.x;
                if (msize !is null)
                    width1 += SPACING + msize.x;
                if (tbsize !is null && getToolBarAlignment() is SWT.TOP)
                    width1 += SPACING + tbsize.x;
                if (msize !is null
                        || (tbsize !is null && getToolBarAlignment() is SWT.TOP))
                    width1 += SPACING;
                size.x = width1;
                if (clsize !is null) {
                    int width2 = clsize.x;
                    if (tbsize !is null && getToolBarAlignment() is SWT.BOTTOM)
                        width2 += SPACING + tbsize.x;
                    width2 += 2 * HMARGIN;
                    size.x = Math.max(width1, width2);
                }
                // height, first row
                size.y = tsize.y;
                if (msize !is null)
                    size.y = Math.max(msize.y, size.y);
                if (tbsize !is null && getToolBarAlignment() is SWT.TOP)
                    size.y = Math.max(tbsize.y, size.y);
                if (size.y > 0)
                    size.y += VMARGIN * 2;
                // add second row
                int height2 = 0;
                if (tbsize !is null && getToolBarAlignment() is SWT.BOTTOM)
                    height2 = tbsize.y;
                if (clsize !is null)
                    height2 = Math.max(height2, clsize.y);
                if (height2 > 0)
                    size.y += VSPACING + height2 + CLIENT_MARGIN;
                // add separator
                if (size.y > 0 && isSeparatorVisible())
                    size.y += SEPARATOR_HEIGHT;
            } else {
                // position controls
                int xloc = x;
                int yloc = y + VMARGIN;
                int row1Height = tsize.y;
                if (hasMessageRegion())
                    row1Height = Math.max(row1Height, msize.y);
                if (hasToolBar() && getToolBarAlignment() is SWT.TOP)
                    row1Height = Math.max(row1Height, tbsize.y);
                titleRegion.setBounds(xloc,
                // yloc + row1Height / 2 - tsize.y / 2,
                        yloc, tsize.x, tsize.y);
                xloc += tsize.x;

                if (hasMessageRegion()) {
                    xloc += SPACING;
                    int messageOffset = 0;
                    if (tsize.y > 0) {
                        // space between title area and title text
                        int titleLeadingSpace = (tsize.y - titleRegion.getFontHeight()) / 2;
                        // space between message control and message text
                        int messageLeadingSpace = (msize.y - messageRegion.getFontHeight()) / 2;
                        // how much to offset the message so baselines align
                        messageOffset = (titleLeadingSpace + titleRegion.getFontBaselineHeight())
                            - (messageLeadingSpace + messageRegion.getFontBaselineHeight());
                    }

                    messageRegion
                            .getMessageControl()
                            .setBounds(
                                    xloc,
                                    tsize.y > 0 ? (yloc + messageOffset)
                                            : (yloc + row1Height / 2 - msize.y / 2),
                                    msize.x, msize.y);
                    xloc += msize.x;
                }
                if (toolBarManager !is null)
                    toolBarManager.getControl().setVisible(
                            !toolBarManager.isEmpty());
                if (tbsize !is null && getToolBarAlignment() is SWT.TOP) {
                    ToolBar tbar = toolBarManager.getControl();
                    tbar.setBounds(x + width - 1 - tbsize.x - HMARGIN, yloc
                            + row1Height - 1 - tbsize.y, tbsize.x, tbsize.y);
                }
                // second row
                xloc = HMARGIN;
                yloc += row1Height + VSPACING;
                int tw = 0;

                if (tbsize !is null && getToolBarAlignment() is SWT.BOTTOM) {
                    ToolBar tbar = toolBarManager.getControl();
                    tbar.setBounds(x + width - 1 - tbsize.x - HMARGIN, yloc,
                            tbsize.x, tbsize.y);
                    tw = tbsize.x + SPACING;
                }
                if (headClient !is null) {
                    int carea = width - HMARGIN * 2 - tw;
                    headClient.setBounds(xloc, yloc, carea, clsize.y);
                }
            }
            return size;
        }
    }
    this(){
        toolbarCache = new SizeCache();
        clientCache = new SizeCache();
        messageCache = new SizeCache();
    }
    /* (non-Javadoc)
     * @see org.eclipse.swt.widgets.Control#forceFocus()
     */
    public bool forceFocus() {
        return false;
    }

    private bool hasToolBar() {
        return toolBarManager !is null && !toolBarManager.isEmpty();
    }

    private bool hasMessageRegion() {
        return messageRegion !is null && !messageRegion.isEmpty();
    }

    private class MessageRegion {
        private String message;
        private int messageType;
        private CLabel messageLabel;
        private IMessage[] messages;
        private Hyperlink messageHyperlink;
        private ListenerList listeners;
        private Color fg;
        private int fontHeight = -1;
        private int fontBaselineHeight = -1;

        public this() {
        }

        public bool isDisposed() {
            Control c = getMessageControl();
            return c !is null && c.isDisposed();
        }

        public bool isEmpty() {
            Control c = getMessageControl();
            if (c is null)
                return true;
            return !c.getVisible();
        }

        public int getFontHeight() {
            if (fontHeight is -1) {
                Control c = getMessageControl();
                if (c is null)
                    return 0;
                GC gc = new GC(c.getDisplay());
                gc.setFont(c.getFont());
                fontHeight = gc.getFontMetrics().getHeight();
                gc.dispose();
            }
            return fontHeight;
        }

        public int getFontBaselineHeight() {
            if (fontBaselineHeight is -1) {
                Control c = getMessageControl();
                if (c is null)
                    return 0;
                GC gc = new GC(c.getDisplay());
                gc.setFont(c.getFont());
                FontMetrics fm = gc.getFontMetrics();
                fontBaselineHeight = fm.getHeight() - fm.getDescent();
                gc.dispose();
            }
            return fontBaselineHeight;
        }

        public void showMessage(String newMessage, int newType,
                IMessage[] messages) {
            Control oldControl = getMessageControl();
            int oldType = messageType;
            this.message = newMessage;
            this.messageType = newType;
            this.messages = messages;
            if (newMessage is null) {
                // clearing of the message
                if (oldControl !is null && oldControl.getVisible())
                    oldControl.setVisible(false);
                return;
            }
            ensureControlExists();
            if (needHyperlink()) {
                messageHyperlink.setText(newMessage);
                messageHyperlink.setHref(new ArrayWrapperObject(arraycast!(Object)(messages)));
            } else {
                messageLabel.setText(newMessage);
            }
            if (oldType !is newType)
                updateForeground();
        }

        public void updateToolTip(String toolTip) {
            Control control = getMessageControl();
            if (control !is null)
                control.setToolTipText(toolTip);
        }

        public String getMessage() {
            return message;
        }

        public int getMessageType() {
            return messageType;
        }

        public IMessage[] getChildrenMessages() {
            return messages;
        }

        public String getDetailedMessage() {
            Control c = getMessageControl();
            if (c !is null)
                return c.getToolTipText();
            return null;
        }

        public Control getMessageControl() {
            if (needHyperlink() && messageHyperlink !is null)
                return messageHyperlink;
            return messageLabel;
        }

        public Image getMessageImage() {
            switch (messageType) {
            case IMessageProvider.INFORMATION:
                return JFaceResources.getImage(Dialog.DLG_IMG_MESSAGE_INFO);
            case IMessageProvider.WARNING:
                return JFaceResources.getImage(Dialog.DLG_IMG_MESSAGE_WARNING);
            case IMessageProvider.ERROR:
                return JFaceResources.getImage(Dialog.DLG_IMG_MESSAGE_ERROR);
            default:
                return null;
            }
        }

        public void addMessageHyperlinkListener(IHyperlinkListener listener) {
            if (listeners is null)
                listeners = new ListenerList();
            listeners.add(cast(Object)listener);
            ensureControlExists();
            if (messageHyperlink !is null)
                messageHyperlink.addHyperlinkListener(listener);
            if (listeners.size() is 1)
                updateForeground();
        }

        private void removeMessageHyperlinkListener(IHyperlinkListener listener) {
            if (listeners !is null) {
                listeners.remove(cast(Object)listener);
                if (messageHyperlink !is null)
                    messageHyperlink.removeHyperlinkListener(listener);
                if (listeners.isEmpty())
                    listeners = null;
                ensureControlExists();
                if (listeners is null && !isDisposed())
                    updateForeground();
            }
        }

        private void ensureControlExists() {
            if (needHyperlink()) {
                if (messageLabel !is null)
                    messageLabel.setVisible(false);
                if (messageHyperlink is null) {
                    messageHyperlink = new Hyperlink(this.outer, SWT.NULL);
                    messageHyperlink.setUnderlined(true);
                    messageHyperlink.setText(message);
                    messageHyperlink.setHref(new ArrayWrapperObject(arraycast!(Object)(messages)));
                    Object[] llist = listeners.getListeners();
                    for (int i = 0; i < llist.length; i++)
                        messageHyperlink
                                .addHyperlinkListener(cast(IHyperlinkListener) llist[i]);
                    if (messageToolTipManager !is null)
                        messageToolTipManager.createToolTip(messageHyperlink, false);
                } else if (!messageHyperlink.getVisible()) {
                    messageHyperlink.setText(message);
                    messageHyperlink.setHref(new ArrayWrapperObject(arraycast!(Object)(messages)));
                    messageHyperlink.setVisible(true);
                }
            } else {
                // need a label
                if (messageHyperlink !is null)
                    messageHyperlink.setVisible(false);
                if (messageLabel is null) {
                    messageLabel = new CLabel(this.outer, SWT.NULL);
                    messageLabel.setText(message);
                    if (messageToolTipManager !is null)
                        messageToolTipManager.createToolTip(messageLabel, false);
                } else if (!messageLabel.getVisible()) {
                    messageLabel.setText(message);
                    messageLabel.setVisible(true);
                }
            }
            layout(true);
        }

        private bool needHyperlink() {
            return messageType > 0 && listeners !is null;
        }

        public void setBackground(Color bg) {
            if (messageHyperlink !is null)
                messageHyperlink.setBackground(bg);
            if (messageLabel !is null)
                messageLabel.setBackground(bg);
        }

        public void setForeground(Color fg) {
            this.fg = fg;
        }

        private void updateForeground() {
            Color theFg;

            switch (messageType) {
            case IMessageProvider.ERROR:
                theFg = getDisplay().getSystemColor(SWT.COLOR_RED);
                break;
            case IMessageProvider.WARNING:
                theFg = getDisplay().getSystemColor(SWT.COLOR_DARK_YELLOW);
                break;
            default:
                theFg = fg;
            }
            getMessageControl().setForeground(theFg);
        }
    }

    /**
     * Creates the form content control as a child of the provided parent.
     *
     * @param parent
     *            the parent widget
     */
    public this(Composite parent, int style) {
        colors = new Hashtable();
        toolbarCache = new SizeCache();
        clientCache = new SizeCache();
        messageCache = new SizeCache();
        messageToolTipManager = new DefaultMessageToolTipManager();

        super(parent, style);
        setBackgroundMode(SWT.INHERIT_DEFAULT);
        addListener(SWT.Paint, new class Listener {
            public void handleEvent(Event e) {
                onPaint(e.gc);
            }
        });
        addListener(SWT.Dispose, new class Listener {
            public void handleEvent(Event e) {
                if (gradientImage !is null) {
                    FormImages.getInstance().markFinished(gradientImage);
                    gradientImage = null;
                }
            }
        });
        addListener(SWT.Resize, new class Listener {
            public void handleEvent(Event e) {
                if (gradientInfo !is null
                        || (backgroundImage !is null && !isBackgroundImageTiled()))
                    updateGradientImage();
            }
        });
        addMouseMoveListener(new class MouseMoveListener {
            public void mouseMove(MouseEvent e) {
                updateTitleRegionHoverState(e);
            }
        });
        addMouseTrackListener(new class MouseTrackListener {
            public void mouseEnter(MouseEvent e) {
                updateTitleRegionHoverState(e);
            }

            public void mouseExit(MouseEvent e) {
                titleRegion.setHoverState(TitleRegion.STATE_NORMAL);
            }

            public void mouseHover(MouseEvent e) {
            }
        });
        super.setLayout(new FormHeadingLayout());
        titleRegion = new TitleRegion(this);
    }

    /**
     * Fully delegates the size computation to the internal layout manager.
     */
    public final Point computeSize(int wHint, int hHint, bool changed) {
        return (cast(FormHeadingLayout) getLayout()).computeSize(this, wHint,
                hHint, changed);
    }

    /**
     * Prevents from changing the custom control layout.
     */
    public final void setLayout(Layout layout) {
    }

    /**
     * Returns the title text that will be rendered at the top of the form.
     *
     * @return the title text
     */
    public String getText() {
        return titleRegion.getText();
    }

    /**
     * Returns the title image that will be rendered to the left of the title.
     *
     * @return the title image
     * @since 3.2
     */
    public Image getImage() {
        return titleRegion.getImage();
    }

    /**
     * Sets the background color of the header.
     */
    public void setBackground(Color bg) {
        super.setBackground(bg);
        internalSetBackground(bg);
    }

    private void internalSetBackground(Color bg) {
        titleRegion.setBackground(bg);
        if (messageRegion !is null)
            messageRegion.setBackground(bg);
        if (toolBarManager !is null)
            toolBarManager.getControl().setBackground(bg);
        putColor(COLOR_BASE_BG, bg);
    }

    /**
     * Sets the foreground color of the header.
     */
    public void setForeground(Color fg) {
        super.setForeground(fg);
        titleRegion.setForeground(fg);
        if (messageRegion !is null)
            messageRegion.setForeground(fg);
    }

    /**
     * Sets the text to be rendered at the top of the form above the body as a
     * title.
     *
     * @param text
     *            the title text
     */
    public void setText(String text) {
        titleRegion.setText(text);
    }

    public void setFont(Font font) {
        super.setFont(font);
        titleRegion.setFont(font);
    }

    /**
     * Sets the image to be rendered to the left of the title.
     *
     * @param image
     *            the title image or <code>null</code> to show no image.
     * @since 3.2
     */
    public void setImage(Image image) {
        titleRegion.setImage(image);
        if (messageRegion !is null)
            titleRegion.updateImage(messageRegion.getMessageImage(), true);
        else
            titleRegion.updateImage(null, true);
    }

    public void setTextBackground(Color[] gradientColors, int[] percents,
            bool vertical) {
        if (gradientColors !is null) {
            gradientInfo = new GradientInfo();
            gradientInfo.gradientColors = gradientColors;
            gradientInfo.percents = percents;
            gradientInfo.vertical = vertical;
            setBackground(null);
            updateGradientImage();
        } else {
            // reset
            gradientInfo = null;
            if (gradientImage !is null) {
                FormImages.getInstance().markFinished(gradientImage);
                gradientImage = null;
                setBackgroundImage(null);
            }
        }
    }

    public void setHeadingBackgroundImage(Image image) {
        this.backgroundImage = image;
        if (image !is null)
            setBackground(null);
        if (isBackgroundImageTiled()) {
            setBackgroundImage(image);
        } else
            updateGradientImage();
    }

    public Image getHeadingBackgroundImage() {
        return backgroundImage;
    }

    public void setBackgroundImageTiled(bool tiled) {
        if (tiled)
            flags |= BACKGROUND_IMAGE_TILED;
        else
            flags &= ~BACKGROUND_IMAGE_TILED;
        setHeadingBackgroundImage(this.backgroundImage);
    }

    public bool isBackgroundImageTiled() {
        return (flags & BACKGROUND_IMAGE_TILED) !is 0;
    }

    public void setBackgroundImage(Image image) {
        super.setBackgroundImage(image);
        if (image !is null) {
            internalSetBackground(null);
        }
    }

    /**
     * Returns the tool bar manager that is used to manage tool items in the
     * form's title area.
     *
     * @return form tool bar manager
     */
    public IToolBarManager getToolBarManager() {
        if (toolBarManager is null) {
            toolBarManager = new ToolBarManager(SWT.FLAT);
            ToolBar toolbar = toolBarManager.createControl(this);
            toolbar.setBackground(getBackground());
            toolbar.setForeground(getForeground());
            toolbar.setCursor(FormsResources.getHandCursor());
            addDisposeListener(new class DisposeListener {
                public void widgetDisposed(DisposeEvent e) {
                    if (toolBarManager !is null) {
                        toolBarManager.dispose();
                        toolBarManager = null;
                    }
                }
            });
        }
        return toolBarManager;
    }

    /**
     * Returns the menu manager that is used to manage tool items in the form's
     * title area.
     *
     * @return form drop-down menu manager
     * @since 3.3
     */
    public IMenuManager getMenuManager() {
        return titleRegion.getMenuManager();
    }

    /**
     * Updates the local tool bar manager if used. Does nothing if local tool
     * bar manager has not been created yet.
     */
    public void updateToolBar() {
        if (toolBarManager !is null)
            toolBarManager.update(false);
    }

    private void onPaint(GC gc) {
        if (!isSeparatorVisible() && getBackgroundImage() is null)
            return;
        Rectangle carea = getClientArea();
        Image buffer = new Image(getDisplay(), carea.width, carea.height);
        buffer.setBackground(getBackground());
        GC igc = new GC(buffer);
        igc.setBackground(getBackground());
        igc.fillRectangle(0, 0, carea.width, carea.height);
        if (getBackgroundImage() !is null) {
            if (gradientInfo !is null)
                drawBackground(igc, carea.x, carea.y, carea.width, carea.height);
            else {
                Image bgImage = getBackgroundImage();
                Rectangle ibounds = bgImage.getBounds();
                drawBackground(igc, carea.x, carea.y, ibounds.width,
                        ibounds.height);
            }
        }

        if (isSeparatorVisible()) {
            // bg separator
            if (hasColor(IFormColors.H_BOTTOM_KEYLINE1))
                igc.setForeground(getColor(IFormColors.H_BOTTOM_KEYLINE1));
            else
                igc.setForeground(getBackground());
            igc.drawLine(carea.x, carea.height - 2, carea.x + carea.width - 1,
                    carea.height - 2);
            if (hasColor(IFormColors.H_BOTTOM_KEYLINE2))
                igc.setForeground(getColor(IFormColors.H_BOTTOM_KEYLINE2));
            else
                igc.setForeground(getForeground());
            igc.drawLine(carea.x, carea.height - 1, carea.x + carea.width - 1,
                    carea.height - 1);
        }
        igc.dispose();
        gc.drawImage(buffer, carea.x, carea.y);
        buffer.dispose();
    }

    private void updateTitleRegionHoverState(MouseEvent e) {
        Rectangle titleRect = titleRegion.getBounds();
        titleRect.width += titleRect.x + 15;
        titleRect.height += titleRect.y + 15;
        titleRect.x = 0;
        titleRect.y = 0;
        if (titleRect.contains(e.x, e.y))
            titleRegion.setHoverState(TitleRegion.STATE_HOVER_LIGHT);
        else
            titleRegion.setHoverState(TitleRegion.STATE_NORMAL);
    }

    private void updateGradientImage() {
        Rectangle rect = getBounds();
        if (gradientImage !is null) {
            FormImages.getInstance().markFinished(gradientImage);
            gradientImage = null;
        }
        if (gradientInfo !is null) {
            gradientImage = FormImages.getInstance().getGradient(getDisplay(), gradientInfo.gradientColors, gradientInfo.percents,
                    gradientInfo.vertical ? rect.height : rect.width, gradientInfo.vertical, getColor(COLOR_BASE_BG));
        } else if (backgroundImage !is null && !isBackgroundImageTiled()) {
            gradientImage = new Image(getDisplay(), Math.max(rect.width, 1),
                    Math.max(rect.height, 1));
            gradientImage.setBackground(getBackground());
            GC gc = new GC(gradientImage);
            gc.drawImage(backgroundImage, 0, 0);
            gc.dispose();
        }
        setBackgroundImage(gradientImage);
    }

    public bool isSeparatorVisible() {
        return (flags & SEPARATOR) !is 0;
    }

    public void setSeparatorVisible(bool addSeparator) {
        if (addSeparator)
            flags |= SEPARATOR;
        else
            flags &= ~SEPARATOR;
    }

    public void setToolBarAlignment(int alignment) {
        if (alignment is SWT.BOTTOM)
            flags |= BOTTOM_TOOLBAR;
        else
            flags &= ~BOTTOM_TOOLBAR;
    }

    public int getToolBarAlignment() {
        return (flags & BOTTOM_TOOLBAR) !is 0 ? SWT.BOTTOM : SWT.TOP;
    }

    public void addMessageHyperlinkListener(IHyperlinkListener listener) {
        ensureMessageRegionExists();
        messageRegion.addMessageHyperlinkListener(listener);
    }

    public void removeMessageHyperlinkListener(IHyperlinkListener listener) {
        if (messageRegion !is null)
            messageRegion.removeMessageHyperlinkListener(listener);
    }

    public String getMessage() {
        return messageRegion !is null ? messageRegion.getMessage() : null;
    }

    public int getMessageType() {
        return messageRegion !is null ? messageRegion.getMessageType() : 0;
    }

    public IMessage[] getChildrenMessages() {
        return messageRegion !is null ? messageRegion.getChildrenMessages()
                : NULL_MESSAGE_ARRAY;
    }

    private void ensureMessageRegionExists() {
        // ensure message region exists
        if (messageRegion is null)
            messageRegion = new MessageRegion();
    }

    public void showMessage(String newMessage, int type, IMessage[] messages) {
        if (messageRegion is null) {
            // check the trivial case
            if (newMessage is null)
                return;
        } else if (messageRegion.isDisposed())
            return;
        ensureMessageRegionExists();
        messageRegion.showMessage(newMessage, type, messages);
        titleRegion.updateImage(messageRegion.getMessageImage(), false);
        if (messageToolTipManager !is null)
            messageToolTipManager.update();
        layout();
        redraw();
    }

    /**
     * Tests if the form is in the 'busy' state.
     *
     * @return <code>true</code> if busy, <code>false</code> otherwise.
     */

    public bool isBusy() {
        return titleRegion.isBusy();
    }

    /**
     * Sets the form's busy state. Busy form will display 'busy' animation in
     * the area of the title image.
     *
     * @param busy
     *            the form's busy state
     */

    public void setBusy(bool busy) {
        if (titleRegion.setBusy(busy))
            layout();
    }

    public Control getHeadClient() {
        return headClient;
    }

    public void setHeadClient(Control headClient) {
        if (headClient !is null)
            Assert.isTrue(headClient.getParent() is this);
        this.headClient = headClient;
        layout();
    }

    public void putColor(String key, Color color) {
        if (color is null)
            colors.remove(key);
        else
            colors.put(key, color);
    }

    public Color getColor(String key) {
        return cast(Color) colors.get(key);
    }

    public bool hasColor(String key) {
        return colors.containsKey(key);
    }

    public void addDragSupport(int operations, Transfer[] transferTypes,
            DragSourceListener listener) {
        titleRegion.addDragSupport(operations, transferTypes, listener);
    }

    public void addDropSupport(int operations, Transfer[] transferTypes,
            DropTargetListener listener) {
        titleRegion.addDropSupport(operations, transferTypes, listener);
    }

    public IMessageToolTipManager getMessageToolTipManager() {
        return messageToolTipManager;
    }

    public void setMessageToolTipManager(
            IMessageToolTipManager messageToolTipManager) {
        this.messageToolTipManager = messageToolTipManager;
    }
}
