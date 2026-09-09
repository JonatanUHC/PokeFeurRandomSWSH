// Bibliotheque de controles dessines pour PokeFeur.
//
// Principe : chaque classe DERIVE du controle systeme qu'elle remplace et n'en
// change que le rendu. PfCheckBox est une CheckBox, PfComboBox une ComboBox.
// L'API publique (.Checked, .Items, .SelectedItem, .Text, les evenements) reste
// identique, ce qui permet de remplacer l'implementation derriere les fabriques
// existantes sans toucher aux 249 sites d'appel du generateur.
//
// Cible : C# 5 / .NET Framework 4.x, compile par Add-Type sous PowerShell 5.1.
// Pas d'interpolation de chaines, pas de membres a corps d'expression.

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Windows.Forms;

namespace PokeFeur.Ui
{
    // ------------------------------------------------------------- jetons ---
    public static class PfTheme
    {
        public static bool Dark = true;

        public static Color Rail      = Color.FromArgb(22, 23, 26);
        public static Color Canvas    = Color.FromArgb(28, 29, 33);
        public static Color Card      = Color.FromArgb(34, 36, 41);
        public static Color CardHi    = Color.FromArgb(41, 43, 50);
        public static Color Sunken    = Color.FromArgb(24, 25, 29);
        public static Color Line      = Color.FromArgb(50, 53, 61);
        public static Color LineSoft  = Color.FromArgb(40, 43, 49);
        public static Color Text      = Color.FromArgb(238, 240, 244);
        public static Color TextSoft  = Color.FromArgb(152, 158, 170);
        public static Color TextFaint = Color.FromArgb(110, 116, 128);
        public static Color Accent    = Color.FromArgb(96, 145, 255);
        public static Color AccentDeep= Color.FromArgb(59, 111, 224);
        public static Color OnAccent  = Color.FromArgb(255, 255, 255);
        public static Color Good      = Color.FromArgb(74, 201, 138);
        public static Color Warn      = Color.FromArgb(233, 178, 82);
        public static Color Bad       = Color.FromArgb(240, 110, 110);

        public static void UseLight()
        {
            Dark      = false;
            Rail      = Color.FromArgb(246, 247, 249);
            Canvas    = Color.FromArgb(252, 252, 253);
            Card      = Color.FromArgb(255, 255, 255);
            CardHi    = Color.FromArgb(238, 241, 246);
            Sunken    = Color.FromArgb(250, 251, 252);
            Line      = Color.FromArgb(219, 223, 230);
            LineSoft  = Color.FromArgb(232, 235, 240);
            Text      = Color.FromArgb(24, 27, 33);
            TextSoft  = Color.FromArgb(94, 101, 114);
            TextFaint = Color.FromArgb(134, 141, 154);
            Accent    = Color.FromArgb(45, 98, 214);
            AccentDeep= Color.FromArgb(38, 88, 200);
            OnAccent  = Color.FromArgb(255, 255, 255);
            Good      = Color.FromArgb(28, 138, 88);
            Warn      = Color.FromArgb(163, 112, 20);
            Bad       = Color.FromArgb(190, 58, 58);
        }

        public static void UseDark()
        {
            Dark      = true;
            Rail      = Color.FromArgb(22, 23, 26);
            Canvas    = Color.FromArgb(28, 29, 33);
            Card      = Color.FromArgb(34, 36, 41);
            CardHi    = Color.FromArgb(41, 43, 50);
            Sunken    = Color.FromArgb(24, 25, 29);
            Line      = Color.FromArgb(50, 53, 61);
            LineSoft  = Color.FromArgb(40, 43, 49);
            Text      = Color.FromArgb(238, 240, 244);
            TextSoft  = Color.FromArgb(152, 158, 170);
            TextFaint = Color.FromArgb(110, 116, 128);
            Accent    = Color.FromArgb(96, 145, 255);
            AccentDeep= Color.FromArgb(59, 111, 224);
            OnAccent  = Color.FromArgb(255, 255, 255);
            Good      = Color.FromArgb(74, 201, 138);
            Warn      = Color.FromArgb(233, 178, 82);
            Bad       = Color.FromArgb(240, 110, 110);
        }
    }

    // ------------------------------------------------------- typographie ---
    public static class PfFont
    {
        static readonly Dictionary<string, Font> _cache = new Dictionary<string, Font>();

        // Segoe UI Variable est la police avec laquelle Windows 11 se dessine
        // lui-meme. Display pour les titres, Text pour le corps : ce ne sont pas
        // deux graisses de la meme police mais deux optiques distinctes.
        static Font Make(string family, float size, FontStyle style)
        {
            try { return new Font(family, size, style); }
            catch { }
            try { return new Font("Segoe UI", size, style); }
            catch { }
            return new Font(FontFamily.GenericSansSerif, size, style);
        }

        public static Font Get(string face, float size, FontStyle style)
        {
            string key = face + "|" + size.ToString() + "|" + ((int)style).ToString();
            lock (_cache)
            {
                if (_cache.ContainsKey(key)) return _cache[key];
                string family;
                if (face == "icon") family = "Segoe Fluent Icons";
                else if (face == "display") family = "Segoe UI Variable Display";
                else family = "Segoe UI Variable Text";
                Font f = Make(family, size, style);
                _cache[key] = f;
                return f;
            }
        }

        public static Font Body      { get { return Get("text", 9.75f, FontStyle.Regular); } }
        public static Font BodyBold  { get { return Get("text", 9.75f, FontStyle.Bold); } }
        public static Font Small     { get { return Get("text", 8.5f, FontStyle.Regular); } }
        public static Font Micro     { get { return Get("text", 7.75f, FontStyle.Bold); } }
        public static Font H1        { get { return Get("display", 12f, FontStyle.Bold); } }
        public static Font Title     { get { return Get("display", 19f, FontStyle.Bold); } }
        public static Font Icon      { get { return Get("icon", 11.5f, FontStyle.Regular); } }
        public static Font IconSmall { get { return Get("icon", 8f, FontStyle.Regular); } }
    }

    // ----------------------------------------------------------- glyphes ---
    // Segoe Fluent Icons. Ecrits en echappement \uXXXX : ce sont des points de
    // code de zone privee. En clair, ils ne survivent pas a un fichier relu en
    // ANSI - le defaut exact qui affichait "GA(c)nA(c)ral" sur la maquette.
    public static class PfGlyph
    {
        public const string Check        = "\uE73E";
        public const string ChevronDown  = "\uE70D";
        public const string ChevronRight = "\uE76C";
        public const string Brand        = "\uE9D9";
        public const string Minimize     = "\uE921";
        public const string Maximize     = "\uE922";
        public const string Close        = "\uE8BB";
        public const string Play         = "\uE768";
        public const string Warning      = "\uE7BA";
        public const string Home         = "\uE80F";
        public const string People       = "\uE716";
        public const string Heart        = "\uE95E";
        public const string Swap         = "\uE8AB";
        public const string Gift         = "\uE719";
        public const string Globe        = "\uE909";
        public const string Settings     = "\uE713";
        public const string Help         = "\uE897";
        public const string Reset        = "\uE72C";
        public const string Folder       = "\uE8B7";
        public const string Save         = "\uE74E";
    }

    // ------------------------------------------------------------ dessin ---
    public static class PfDraw
    {
        public static GraphicsPath Rounded(Rectangle r, int radius)
        {
            GraphicsPath p = new GraphicsPath();
            int d = radius * 2;
            if (d <= 0) { p.AddRectangle(r); return p; }
            if (d > r.Width) d = r.Width;
            if (d > r.Height) d = r.Height;
            p.AddArc(r.X, r.Y, d, d, 180, 90);
            p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
            p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
            p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
            p.CloseFigure();
            return p;
        }

        public static void Fill(Graphics g, Rectangle r, int radius, Color c)
        {
            using (GraphicsPath p = Rounded(r, radius))
            using (SolidBrush b = new SolidBrush(c))
                g.FillPath(b, p);
        }

        public static void Stroke(Graphics g, Rectangle r, int radius, Color c, float w)
        {
            // Un trait de 1px sur un rectangle entier deborde d'un demi-pixel :
            // on retrecit de 1 pour que la bordure reste dans les limites.
            Rectangle rr = new Rectangle(r.X, r.Y, r.Width - 1, r.Height - 1);
            using (GraphicsPath p = Rounded(rr, radius))
            using (Pen pen = new Pen(c, w))
                g.DrawPath(pen, p);
        }

        public static void Text(Graphics g, string s, Font f, Color c, Rectangle r, ContentAlignment align)
        {
            TextFormatFlags flags = TextFormatFlags.NoPadding | TextFormatFlags.EndEllipsis
                                  | TextFormatFlags.VerticalCenter;
            if (align == ContentAlignment.MiddleCenter) flags |= TextFormatFlags.HorizontalCenter;
            if (align == ContentAlignment.MiddleRight) flags |= TextFormatFlags.Right;
            TextRenderer.DrawText(g, s, f, r, c, flags);
        }

        public static void Prepare(Graphics g)
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        }

        public static Color Mix(Color a, Color b, double t)
        {
            return Color.FromArgb(
                (int)(a.R + (b.R - a.R) * t),
                (int)(a.G + (b.G - a.G) * t),
                (int)(a.B + (b.B - a.B) * t));
        }
    }

    // --------------------------------------------------------- base commune ---
    public class PfControl : Control
    {
        protected bool Hot;
        protected bool Down;

        public PfControl()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint
                   | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw
                   | ControlStyles.SupportsTransparentBackColor, true);
        }

        protected override void OnMouseEnter(EventArgs e) { Hot = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { Hot = false; Down = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnMouseDown(MouseEventArgs e) { Down = true; Invalidate(); base.OnMouseDown(e); }
        protected override void OnMouseUp(MouseEventArgs e) { Down = false; Invalidate(); base.OnMouseUp(e); }
    }

    // ------------------------------------------------------------- carte ---
    public class PfCard : Panel
    {
        public string Title = "";
        public string Subtitle = "";

        public PfCard()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint
                   | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            BackColor = PfTheme.Card;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            PfDraw.Prepare(g);
            Rectangle r = new Rectangle(0, 0, Width, Height);
            using (SolidBrush bg = new SolidBrush(Parent != null ? Parent.BackColor : PfTheme.Canvas))
                g.FillRectangle(bg, r);
            PfDraw.Fill(g, r, 10, PfTheme.Card);
            PfDraw.Stroke(g, r, 10, PfTheme.Line, 1f);
            if (!string.IsNullOrEmpty(Title))
                PfDraw.Text(g, Title, PfFont.H1, PfTheme.Text, new Rectangle(24, 20, Width - 48, 24), ContentAlignment.MiddleLeft);
            if (!string.IsNullOrEmpty(Subtitle))
                PfDraw.Text(g, Subtitle, PfFont.Small, PfTheme.TextFaint, new Rectangle(24, 44, Width - 48, 20), ContentAlignment.MiddleLeft);
            base.OnPaint(e);
        }
    }

    // -------------------------------------------------------- case a cocher ---
    public class PfCheckBox : CheckBox
    {
        bool _hot;

        public PfCheckBox()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint
                   | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw
                   | ControlStyles.SupportsTransparentBackColor, true);
            BackColor = Color.Transparent;
            Font = PfFont.Body;
            AutoEllipsis = true;
            Cursor = Cursors.Hand;
        }

        protected override void OnMouseEnter(EventArgs e) { _hot = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { _hot = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnCheckedChanged(EventArgs e) { Invalidate(); base.OnCheckedChanged(e); }
        protected override void OnEnter(EventArgs e) { Invalidate(); base.OnEnter(e); }
        protected override void OnLeave(EventArgs e) { Invalidate(); base.OnLeave(e); }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            PfDraw.Prepare(g);
            using (SolidBrush bg = new SolidBrush(Parent != null ? Parent.BackColor : PfTheme.Card))
                g.FillRectangle(bg, ClientRectangle);

            int box = 18;
            int top = (Height - box) / 2;
            Rectangle b = new Rectangle(1, top, box, box);

            if (Checked)
            {
                PfDraw.Fill(g, b, 5, _hot ? PfTheme.Accent : PfTheme.AccentDeep);
                PfDraw.Text(g, "\uE73E", PfFont.IconSmall, PfTheme.OnAccent, b, ContentAlignment.MiddleCenter);
            }
            else
            {
                PfDraw.Fill(g, b, 5, PfTheme.Sunken);
                PfDraw.Stroke(g, b, 5, _hot ? PfTheme.TextFaint : PfTheme.Line, 1f);
            }

            if (Focused)
            {
                Rectangle fr = new Rectangle(b.X - 3, b.Y - 3, b.Width + 6, b.Height + 6);
                PfDraw.Stroke(g, fr, 7, PfTheme.Accent, 1f);
            }

            Color fg = Enabled ? PfTheme.Text : PfTheme.TextFaint;
            PfDraw.Text(g, Text, Font, fg, new Rectangle(box + 13, 0, Width - box - 13, Height), ContentAlignment.MiddleLeft);
        }
    }

    // ------------------------------------------------------- interrupteur ---
    // Meme API qu'une CheckBox : c'est une CheckBox. Seul le dessin change.
    public class PfToggle : CheckBox
    {
        bool _hot;
        public string Subtitle = "";

        public PfToggle()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint
                   | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw
                   | ControlStyles.SupportsTransparentBackColor, true);
            BackColor = Color.Transparent;
            Font = PfFont.Body;
            Cursor = Cursors.Hand;
            Height = 44;
        }

        protected override void OnMouseEnter(EventArgs e) { _hot = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { _hot = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnCheckedChanged(EventArgs e) { Invalidate(); base.OnCheckedChanged(e); }
        protected override void OnEnter(EventArgs e) { Invalidate(); base.OnEnter(e); }
        protected override void OnLeave(EventArgs e) { Invalidate(); base.OnLeave(e); }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            PfDraw.Prepare(g);
            using (SolidBrush bg = new SolidBrush(Parent != null ? Parent.BackColor : PfTheme.Card))
                g.FillRectangle(bg, ClientRectangle);

            if (_hot)
                PfDraw.Fill(g, new Rectangle(-8, 0, Width + 16, Height), 8, PfTheme.CardHi);

            int tw = 38, th = 21;
            int tx = Width - tw - 2;
            int ty = (Height - th) / 2;
            Rectangle track = new Rectangle(tx, ty, tw, th);

            if (Checked)
            {
                PfDraw.Fill(g, track, 10, _hot ? PfTheme.Accent : PfTheme.AccentDeep);
            }
            else
            {
                PfDraw.Fill(g, track, 10, PfTheme.Sunken);
                PfDraw.Stroke(g, track, 10, _hot ? PfTheme.TextFaint : PfTheme.Line, 1f);
            }

            int kx = Checked ? tx + tw - 18 : tx + 3;
            using (SolidBrush knob = new SolidBrush(Checked ? Color.White : PfTheme.TextSoft))
                g.FillEllipse(knob, kx, ty + 3, 15, 15);

            if (Focused)
                PfDraw.Stroke(g, new Rectangle(track.X - 3, track.Y - 3, track.Width + 6, track.Height + 6), 13, PfTheme.Accent, 1f);

            int textW = Width - tw - 24;
            if (string.IsNullOrEmpty(Subtitle))
            {
                PfDraw.Text(g, Text, Font, PfTheme.Text, new Rectangle(0, 0, textW, Height), ContentAlignment.MiddleLeft);
            }
            else
            {
                PfDraw.Text(g, Text, Font, PfTheme.Text, new Rectangle(0, 4, textW, 20), ContentAlignment.MiddleLeft);
                PfDraw.Text(g, Subtitle, PfFont.Small, PfTheme.TextFaint, new Rectangle(0, 23, textW, 18), ContentAlignment.MiddleLeft);
            }
        }
    }

    // ------------------------------------------------------------ bouton ---
    public class PfButton : Button
    {
        bool _hot, _down;
        public bool Primary = false;
        public string Glyph = "";

        public PfButton()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint
                   | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw
                   | ControlStyles.SupportsTransparentBackColor, true);
            FlatStyle = FlatStyle.Flat;
            FlatAppearance.BorderSize = 0;
            BackColor = Color.Transparent;
            Font = PfFont.BodyBold;
            Cursor = Cursors.Hand;
            Height = 38;
        }

        protected override void OnMouseEnter(EventArgs e) { _hot = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { _hot = false; _down = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnMouseDown(MouseEventArgs e) { _down = true; Invalidate(); base.OnMouseDown(e); }
        protected override void OnMouseUp(MouseEventArgs e) { _down = false; Invalidate(); base.OnMouseUp(e); }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            PfDraw.Prepare(g);
            using (SolidBrush bg = new SolidBrush(Parent != null ? Parent.BackColor : PfTheme.Canvas))
                g.FillRectangle(bg, ClientRectangle);

            Rectangle r = new Rectangle(0, 0, Width, Height);
            Color fg;
            if (Primary)
            {
                Color fill = PfTheme.AccentDeep;
                if (_hot) fill = PfTheme.Accent;
                if (_down) fill = PfDraw.Mix(PfTheme.AccentDeep, Color.Black, 0.18);
                if (!Enabled) fill = PfTheme.Line;
                PfDraw.Fill(g, r, 8, fill);
                fg = Enabled ? PfTheme.OnAccent : PfTheme.TextFaint;
            }
            else
            {
                if (_hot) PfDraw.Fill(g, r, 8, PfTheme.CardHi);
                PfDraw.Stroke(g, r, 8, _hot ? PfTheme.TextFaint : PfTheme.Line, 1f);
                fg = Enabled ? PfTheme.Text : PfTheme.TextFaint;
            }

            if (string.IsNullOrEmpty(Glyph))
            {
                PfDraw.Text(g, Text, Font, fg, r, ContentAlignment.MiddleCenter);
            }
            else
            {
                Size ts = TextRenderer.MeasureText(Text, Font);
                int total = ts.Width + 22;
                int sx = (Width - total) / 2;
                PfDraw.Text(g, Glyph, PfFont.IconSmall, fg, new Rectangle(sx, 0, 16, Height), ContentAlignment.MiddleCenter);
                PfDraw.Text(g, Text, Font, fg, new Rectangle(sx + 22, 0, ts.Width + 4, Height), ContentAlignment.MiddleLeft);
            }

            if (Focused && Enabled)
                PfDraw.Stroke(g, new Rectangle(2, 2, Width - 4, Height - 4), 6, Primary ? PfTheme.OnAccent : PfTheme.Accent, 1f);
        }
    }

    // ------------------------------------------------- liste deroulante ---
    // On garde la ComboBox systeme (donc toute son API et son comportement
    // clavier) et on repeint sa face fermee par-dessus, plus les elements de la
    // liste en owner-draw.
    public class PfComboBox : ComboBox
    {
        const int WM_PAINT = 0x000F;
        bool _hot;

        public PfComboBox()
        {
            DropDownStyle = ComboBoxStyle.DropDownList;
            DrawMode = DrawMode.OwnerDrawFixed;
            FlatStyle = FlatStyle.Flat;
            /* Une ComboBox ignore la hauteur qu'on lui donne : elle la derive
               de ItemHeight plus 6 pixels de chrome. Mesure : ItemHeight 26
               donnait un controle de 32, ItemHeight 22 en donne 28 - la
               hauteur pour laquelle la disposition du generateur a ete
               calibree. Mesure : les rangees sont espacees de 24 px, et
               WinForms rendait la ComboBox d'origine a ~21 px malgre le
               Size(w,28) demande. ItemHeight 18 donne 24, ce qui tient. */
            ItemHeight = 18;
            Font = PfFont.Body;
            BackColor = PfTheme.Sunken;
            ForeColor = PfTheme.Text;
            Cursor = Cursors.Hand;
        }

        protected override void OnMouseEnter(EventArgs e) { _hot = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { _hot = false; Invalidate(); base.OnMouseLeave(e); }

        protected override void OnDrawItem(DrawItemEventArgs e)
        {
            if (e.Index < 0) return;
            Graphics g = e.Graphics;
            PfDraw.Prepare(g);
            bool sel = (e.State & DrawItemState.Selected) == DrawItemState.Selected;
            using (SolidBrush b = new SolidBrush(sel ? PfTheme.CardHi : PfTheme.Card))
                g.FillRectangle(b, e.Bounds);
            if (sel)
                using (SolidBrush b = new SolidBrush(PfTheme.Accent))
                    g.FillRectangle(b, e.Bounds.X, e.Bounds.Y + 6, 3, e.Bounds.Height - 12);
            // GetItemText, pas ToString : le generateur remplit Items avec des
            // objets et nomme la propriete a afficher via DisplayMember (42 sites).
            // ToString y renverrait le nom du type.
            string s = GetItemText(Items[e.Index]);
            PfDraw.Text(g, s, Font, PfTheme.Text,
                new Rectangle(e.Bounds.X + 13, e.Bounds.Y, e.Bounds.Width - 20, e.Bounds.Height),
                ContentAlignment.MiddleLeft);
        }

        void PaintFace(Graphics g)
        {
            PfDraw.Prepare(g);
            Rectangle r = new Rectangle(0, 0, Width, Height);
            using (SolidBrush bg = new SolidBrush(Parent != null ? Parent.BackColor : PfTheme.Card))
                g.FillRectangle(bg, r);
            PfDraw.Fill(g, r, 7, PfTheme.Sunken);
            Color border = PfTheme.Line;
            if (_hot) border = PfTheme.TextFaint;
            if (Focused || DroppedDown) border = PfTheme.Accent;
            PfDraw.Stroke(g, r, 7, border, (Focused || DroppedDown) ? 1.4f : 1f);
            string s = SelectedItem == null ? "" : GetItemText(SelectedItem);
            PfDraw.Text(g, s, Font, Enabled ? PfTheme.Text : PfTheme.TextFaint,
                new Rectangle(13, 0, Width - 42, Height), ContentAlignment.MiddleLeft);
            PfDraw.Text(g, PfGlyph.ChevronDown, PfFont.IconSmall, PfTheme.TextSoft,
                new Rectangle(Width - 28, 0, 18, Height), ContentAlignment.MiddleCenter);
        }

        protected override void WndProc(ref Message m)
        {
            // On ne laisse PAS la ComboBox se peindre. Repeindre par-dessus ne
            // suffisait pas : son bouton systeme ressortait dans le coin haut
            // droit. On prend la main sur WM_PAINT et on valide la zone
            // nous-memes ; la liste deroulante est une autre fenetre et continue
            // de fonctionner normalement.
            if (m.Msg == WM_PAINT && !DesignMode)
            {
                NativeMethods.PAINTSTRUCT ps;
                IntPtr hdc = NativeMethods.BeginPaint(Handle, out ps);
                if (hdc != IntPtr.Zero)
                {
                    try
                    {
                        using (Graphics g = Graphics.FromHdc(hdc))
                            PaintFace(g);
                    }
                    finally { NativeMethods.EndPaint(Handle, ref ps); }
                }
                m.Result = IntPtr.Zero;
                return;
            }
            base.WndProc(ref m);
        }
    }

    // ------------------------------------------------------ champ de texte ---
    // Une TextBox est un controle natif : on ne peut pas repeindre sa zone
    // cliente sans effacer le texte. On elargit donc la zone NON cliente et on
    // dessine la bordure arrondie dedans. L'API TextBox reste entiere.
    public class PfTextBox : TextBox
    {
        const int WM_NCCALCSIZE = 0x0083;
        const int WM_NCPAINT = 0x0085;
        const int PAD_X = 12;
        bool _hot;

        // Une TextBox simple ligne s'auto-dimensionne sur la hauteur de sa
        // police : mesure faite, elle ramenait un controle demande a 36 px a 18.
        // AutoSize desactive, la hauteur demandee tient, et le rembourrage
        // vertical se calcule pour centrer le texte quelle que soit la taille.
        int PadY
        {
            get
            {
                // En multiligne, centrer sur la hauteur de la police n'a aucun
                // sens : une zone de 200 px reserverait 90 px de marge et
                // ecraserait le texte au milieu. Rembourrage fixe.
                if (Multiline) return 8;
                int p = (Height - Font.Height) / 2;
                if (p < 2) p = 2;
                return p;
            }
        }

        public PfTextBox()
        {
            BorderStyle = BorderStyle.None;
            AutoSize = false;
            Font = PfFont.Body;
            Height = 24;
            ApplyPalette();
        }

        void ApplyPalette()
        {
            BackColor = ReadOnly ? PfTheme.CardHi : PfTheme.Sunken;
            ForeColor = PfTheme.Text;
        }

        protected override void OnReadOnlyChanged(EventArgs e)
        {
            base.OnReadOnlyChanged(e);
            // Passer une TextBox en lecture seule REINITIALISE BackColor sur la
            // couleur systeme. Le panneau d'aide se retrouvait blanc avec du
            // texte gris clair, illisible. On remet la palette apres coup.
            ApplyPalette();
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            ApplyPalette();
            NativeMethods.RefreshFrame(Handle);
        }

        protected override void OnSizeChanged(EventArgs e)
        {
            base.OnSizeChanged(e);
            if (IsHandleCreated) NativeMethods.RefreshFrame(Handle);
        }

        protected override void OnMouseEnter(EventArgs e) { _hot = true; RedrawFrame(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { _hot = false; RedrawFrame(); base.OnMouseLeave(e); }
        protected override void OnEnter(EventArgs e)
        {
            // Une zone en lecture seule qui recoit le focus selectionne tout
            // son contenu : le panneau d'aide s'affichait entierement surligne
            // en blanc des qu'on ouvrait son onglet.
            if (ReadOnly)
            {
                SelectionStart = 0;
                SelectionLength = 0;
            }
            RedrawFrame();
            base.OnEnter(e);
        }
        protected override void OnLeave(EventArgs e) { RedrawFrame(); base.OnLeave(e); }

        void RedrawFrame()
        {
            if (IsHandleCreated)
                NativeMethods.RedrawWindow(Handle, IntPtr.Zero, IntPtr.Zero,
                    NativeMethods.RDW_FRAME | NativeMethods.RDW_INVALIDATE | NativeMethods.RDW_UPDATENOW);
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == WM_NCCALCSIZE && m.WParam != IntPtr.Zero)
            {
                NativeMethods.NCCALCSIZE_PARAMS p =
                    (NativeMethods.NCCALCSIZE_PARAMS)System.Runtime.InteropServices.Marshal.PtrToStructure(
                        m.LParam, typeof(NativeMethods.NCCALCSIZE_PARAMS));
                int padY = PadY;
                p.rgrc0.Left += PAD_X;
                p.rgrc0.Right -= PAD_X;
                p.rgrc0.Top += padY;
                p.rgrc0.Bottom -= padY;
                System.Runtime.InteropServices.Marshal.StructureToPtr(p, m.LParam, false);
                m.Result = IntPtr.Zero;
                return;
            }

            if (m.Msg == WM_NCPAINT)
            {
                // Graphics.FromHwnd donne un contexte sur la zone CLIENTE : on
                // n'y atteint jamais la bordure. GetWindowDC couvre la fenetre
                // entiere, bordure comprise, en coordonnees fenetre.
                IntPtr hdc = NativeMethods.GetWindowDC(Handle);
                if (hdc != IntPtr.Zero)
                {
                    try
                    {
                        using (Graphics g = Graphics.FromHdc(hdc))
                        {
                            PfDraw.Prepare(g);
                            Rectangle r = new Rectangle(0, 0, Width, Height);
                            PfDraw.Fill(g, r, 7, ReadOnly ? PfTheme.CardHi : PfTheme.Sunken);
                            Color border = PfTheme.Line;
                            if (_hot) border = PfTheme.TextFaint;
                            if (Focused) border = PfTheme.Accent;
                            PfDraw.Stroke(g, r, 7, border, Focused ? 1.4f : 1f);
                        }
                    }
                    finally { NativeMethods.ReleaseDC(Handle, hdc); }
                }
                m.Result = IntPtr.Zero;
                return;
            }

            base.WndProc(ref m);
        }
    }

    // ------------------------------------------------- rail de navigation ---
    public class PfNavItem
    {
        public string Glyph = "";
        public string Label = "";
        public string Badge = "";
        public string Group = "";
        public PfNavItem(string glyph, string label, string group)
        {
            Glyph = glyph; Label = label; Group = group;
        }
    }

    public class PfNavRail : Panel
    {
        public List<PfNavItem> Items = new List<PfNavItem>();
        public string Brand = "PokeFeur";
        public string BrandSub = "";
        public string StatusText = "";
        public string StatusSub = "";
        public bool StatusOk = true;

        int _selected = 0;
        int _hover = -1;
        readonly List<Rectangle> _hit = new List<Rectangle>();

        public event EventHandler SelectedIndexChanged;

        public int SelectedIndex
        {
            get { return _selected; }
            set
            {
                if (value == _selected || value < 0 || value >= Items.Count) return;
                _selected = value;
                Invalidate();
                if (SelectedIndexChanged != null) SelectedIndexChanged(this, EventArgs.Empty);
            }
        }

        public PfNavRail()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint
                   | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            BackColor = PfTheme.Rail;
            Width = 248;
        }

        protected override void OnSizeChanged(EventArgs e)
        {
            base.OnSizeChanged(e);
            BuildLayout();
        }

        /* Les rectangles cliquables etaient remplis dans OnPaint. Un controle
           devenait donc cliquable seulement APRES avoir ete peint : avant le
           premier rendu, la liste etait vide et aucun clic n'aboutissait. On
           calcule la disposition a part, et on l'appelle aussi bien depuis le
           dessin que depuis la souris. */
        void BuildLayout()
        {
            _hit.Clear();
            int y = 92;
            string group = null;
            for (int i = 0; i < Items.Count; i++)
            {
                if (Items[i].Group != group)
                {
                    group = Items[i].Group;
                    if (!string.IsNullOrEmpty(group)) y += 26;
                }
                _hit.Add(new Rectangle(12, y, Width - 26, 40));
                y += 44;
            }
        }

        int HitTest(Point p)
        {
            if (_hit.Count != Items.Count) BuildLayout();
            for (int i = 0; i < _hit.Count; i++)
                if (_hit[i].Contains(p)) return i;
            return -1;
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            int h = HitTest(e.Location);
            if (h != _hover) { _hover = h; Cursor = h >= 0 ? Cursors.Hand : Cursors.Default; Invalidate(); }
            base.OnMouseMove(e);
        }

        protected override void OnMouseLeave(EventArgs e) { _hover = -1; Invalidate(); base.OnMouseLeave(e); }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            int h = HitTest(e.Location);
            if (h >= 0) SelectedIndex = h;
            base.OnMouseDown(e);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            PfDraw.Prepare(g);
            using (SolidBrush b = new SolidBrush(PfTheme.Rail))
                g.FillRectangle(b, ClientRectangle);
            using (Pen p = new Pen(PfTheme.LineSoft))
                g.DrawLine(p, Width - 1, 0, Width - 1, Height);

            PfDraw.Fill(g, new Rectangle(24, 26, 34, 34), 10, PfTheme.AccentDeep);
            PfDraw.Text(g, "\uE9D9", PfFont.Icon, PfTheme.OnAccent, new Rectangle(24, 26, 34, 34), ContentAlignment.MiddleCenter);
            PfDraw.Text(g, Brand, PfFont.Get("display", 12f, FontStyle.Bold), PfTheme.Text, new Rectangle(70, 28, 160, 20), ContentAlignment.MiddleLeft);
            PfDraw.Text(g, BrandSub, PfFont.Small, PfTheme.TextFaint, new Rectangle(70, 47, 160, 16), ContentAlignment.MiddleLeft);

            BuildLayout();
            int y = 92;
            string group = null;
            for (int i = 0; i < Items.Count; i++)
            {
                PfNavItem it = Items[i];
                if (it.Group != group)
                {
                    group = it.Group;
                    if (!string.IsNullOrEmpty(group))
                    {
                        PfDraw.Text(g, group.ToUpperInvariant(), PfFont.Micro, PfTheme.TextFaint, new Rectangle(26, y, 200, 16), ContentAlignment.MiddleLeft);
                        y += 26;
                    }
                }

                Rectangle row = _hit[i];

                Color fg = PfTheme.TextSoft;
                if (i == _selected)
                {
                    PfDraw.Fill(g, row, 8, PfTheme.CardHi);
                    PfDraw.Fill(g, new Rectangle(12, y + 12, 3, 16), 2, PfTheme.Accent);
                    fg = PfTheme.Text;
                }
                else if (i == _hover)
                {
                    PfDraw.Fill(g, row, 8, PfDraw.Mix(PfTheme.Rail, PfTheme.CardHi, 0.5));
                    fg = PfTheme.Text;
                }

                PfDraw.Text(g, it.Glyph, PfFont.Icon, fg, new Rectangle(32, y, 22, 40), ContentAlignment.MiddleLeft);
                PfDraw.Text(g, it.Label, PfFont.Body, fg, new Rectangle(66, y, Width - 130, 40), ContentAlignment.MiddleLeft);

                if (!string.IsNullOrEmpty(it.Badge))
                {
                    Rectangle br = new Rectangle(Width - 60, y + 12, 24, 16);
                    PfDraw.Fill(g, br, 8, PfTheme.LineSoft);
                    PfDraw.Text(g, it.Badge, PfFont.Small, PfTheme.TextSoft, br, ContentAlignment.MiddleCenter);
                }

                y += 44;
            }

            if (!string.IsNullOrEmpty(StatusText))
            {
                int fy = Height - 100;
                using (Pen p = new Pen(PfTheme.LineSoft))
                    g.DrawLine(p, 24, fy, Width - 24, fy);
                using (SolidBrush b = new SolidBrush(StatusOk ? PfTheme.Good : PfTheme.Warn))
                    g.FillEllipse(b, 27, fy + 26, 8, 8);
                PfDraw.Text(g, StatusText, PfFont.Body, PfTheme.TextSoft, new Rectangle(45, fy + 18, Width - 60, 20), ContentAlignment.MiddleLeft);
                PfDraw.Text(g, StatusSub, PfFont.Small, PfTheme.TextFaint, new Rectangle(45, fy + 38, Width - 60, 18), ContentAlignment.MiddleLeft);
            }
        }
    }

    // ---------------------------------------------------- barre de titre ---
    public class PfTitleBar : Panel
    {
        public string Caption = "";
        int _hover = -1;   // 0 reduire, 1 agrandir, 2 fermer

        public PfTitleBar()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint
                   | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            Height = 40;
            BackColor = PfTheme.Canvas;
        }

        Rectangle BtnRect(int i) { return new Rectangle(Width - 46 * (3 - i), 0, 46, Height); }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            int h = -1;
            for (int i = 0; i < 3; i++) if (BtnRect(i).Contains(e.Location)) h = i;
            if (h != _hover) { _hover = h; Invalidate(); }
            base.OnMouseMove(e);
        }

        protected override void OnMouseLeave(EventArgs e) { _hover = -1; Invalidate(); base.OnMouseLeave(e); }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            Form f = FindForm();
            if (f == null) { base.OnMouseDown(e); return; }
            for (int i = 0; i < 3; i++)
            {
                if (BtnRect(i).Contains(e.Location))
                {
                    if (i == 0) f.WindowState = FormWindowState.Minimized;
                    else if (i == 1) f.WindowState = f.WindowState == FormWindowState.Maximized ? FormWindowState.Normal : FormWindowState.Maximized;
                    else f.Close();
                    return;
                }
            }
            if (e.Button == MouseButtons.Left)
            {
                NativeMethods.ReleaseCapture();
                NativeMethods.SendMessage(f.Handle, 0xA1, (IntPtr)2, IntPtr.Zero);
            }
            base.OnMouseDown(e);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            PfDraw.Prepare(g);
            using (SolidBrush b = new SolidBrush(BackColor))
                g.FillRectangle(b, ClientRectangle);
            if (!string.IsNullOrEmpty(Caption))
                PfDraw.Text(g, Caption, PfFont.Small, PfTheme.TextFaint, new Rectangle(16, 0, Width - 160, Height), ContentAlignment.MiddleLeft);

            string[] glyphs = new string[] { "\uE921", "\uE922", "\uE8BB" };
            for (int i = 0; i < 3; i++)
            {
                Rectangle r = BtnRect(i);
                if (_hover == i)
                    using (SolidBrush b = new SolidBrush(i == 2 ? Color.FromArgb(196, 43, 28) : PfTheme.CardHi))
                        g.FillRectangle(b, r);
                Color fg = (_hover == i && i == 2) ? Color.White : PfTheme.TextSoft;
                PfDraw.Text(g, glyphs[i], PfFont.IconSmall, fg, r, ContentAlignment.MiddleCenter);
            }
        }
    }

    // ------------------------------------------------------------ natif ---
    public static class NativeMethods
    {
        public const int RDW_INVALIDATE = 0x0001;
        public const int RDW_UPDATENOW = 0x0100;
        public const int RDW_FRAME = 0x0400;

        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        public struct RECT { public int Left, Top, Right, Bottom; }

        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        public struct NCCALCSIZE_PARAMS
        {
            public RECT rgrc0, rgrc1, rgrc2;
            public IntPtr lppos;
        }

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern bool RedrawWindow(IntPtr hWnd, IntPtr lprcUpdate, IntPtr hrgnUpdate, int flags);

        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        public struct PAINTSTRUCT
        {
            public IntPtr hdc;
            public bool fErase;
            public RECT rcPaint;
            public bool fRestore;
            public bool fIncUpdate;
            [System.Runtime.InteropServices.MarshalAs(
                System.Runtime.InteropServices.UnmanagedType.ByValArray, SizeConst = 32)]
            public byte[] rgbReserved;
        }

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern IntPtr BeginPaint(IntPtr hWnd, out PAINTSTRUCT ps);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern bool EndPaint(IntPtr hWnd, ref PAINTSTRUCT ps);

        public const int SWP_NOSIZE = 0x0001;
        public const int SWP_NOMOVE = 0x0002;
        public const int SWP_NOZORDER = 0x0004;
        public const int SWP_NOACTIVATE = 0x0010;
        public const int SWP_FRAMECHANGED = 0x0020;

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, int flags);

        // Sans FRAMECHANGED, Windows ne redemande jamais le calcul de la zone
        // non cliente d'un controle enfant : WM_NCCALCSIZE ne part pas et la
        // bordure dessinee n'apparait jamais.
        public static void RefreshFrame(IntPtr hWnd)
        {
            SetWindowPos(hWnd, IntPtr.Zero, 0, 0, 0, 0,
                SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
        }

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern IntPtr GetWindowDC(IntPtr hWnd);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern bool ReleaseCapture();

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);

        [System.Runtime.InteropServices.DllImport("dwmapi.dll")]
        public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);

        // Coins arrondis (33 -> 2 = ROUND) et barre de titre sombre (20).
        // Sans effet avant Windows 11 ; la valeur de retour le dit.
        public static void ApplyWindowChrome(IntPtr hwnd, bool dark)
        {
            int round = 2;
            DwmSetWindowAttribute(hwnd, 33, ref round, 4);
            int d = dark ? 1 : 0;
            DwmSetWindowAttribute(hwnd, 20, ref d, 4);
        }
    }
}
