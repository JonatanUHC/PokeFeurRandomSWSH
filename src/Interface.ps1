# ---------------------------------------------------------------------------
# COUCHE INTERFACE
#
# Extrait de CustomSwShRandomizer.ps1 le 2026-09-06. Ce fichier contient TOUT
# ce qui touche a l'affichage - la bibliotheque de controles dessines, les
# fabriques, la coque, les cartes et Show-Gui - et RIEN d'autre.
#
# Pourquoi cette coupe-la : le bloc va d'un seul tenant de
# Initialize-PfControlLibrary a la fin de Show-Gui, il ne contient aucune
# occurrence de $PSScriptRoot - donc aucun chemin a reecrire une fois le
# fichier deplace - et il ne definit aucune variable que le generateur lit.
# C'est la seule frontiere du fichier qui remplissait ces trois conditions.
#
# Il est charge par point-source depuis le script principal : ses fonctions et
# ses variables restent dans la MEME portee, donc aucun appel n'a change.
#
# BOM UTF-8 obligatoire. Sans lui, PowerShell 5.1 lit ce fichier en ANSI et
# tous les accents de l'interface deviennent illisibles.
# ---------------------------------------------------------------------------

# <PfControlLibrary> --- genere par tools/sync-ui-library.py, ne pas editer ici
function Initialize-PfControlLibrary {
    if ("PokeFeur.Ui.PfTheme" -as [type]) {
        return
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $source = @'
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

        // Le panneau d'aide et la barre d'etat sont poses a meme le canvas, sans
        // carte autour : une bordure PfTheme.Line (50,53,61) sur un fond
        // (28,29,33) etait quasi invisible et l'encadre disparaissait. Emphasized
        // monte le contraste de la bordure UNIQUEMENT sur ces zones-la, sans
        // toucher aux champs de saisie normaux poses sur une carte.
        public bool Emphasized = false;

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
                // ecraserait le texte au milieu. Rembourrage fixe...
                // ... SAUF si la zone est trop basse pour lui : 8 px en haut ET
                // en bas sur une barre d'etat de 24 px ne laissaient que 8 px de
                // texte, soit la moitie superieure des lettres. On rend alors le
                // rembourrage au texte jusqu'a ce qu'une ligne entiere tienne.
                if (Multiline)
                {
                    int pm = 8;
                    while (pm > 1 && Height - (2 * pm) < Font.Height) pm--;
                    return pm;
                }
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
                            Color border = Emphasized ? PfTheme.TextSoft : PfTheme.Line;
                            if (_hot) border = Emphasized ? PfTheme.Text : PfTheme.TextFaint;
                            if (Focused) border = PfTheme.Accent;
                            float bw = Focused ? 1.6f : (Emphasized ? 1.4f : 1f);
                            PfDraw.Stroke(g, r, 7, border, bw);
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
'@

    Add-Type -TypeDefinition $source -ReferencedAssemblies @("System.Windows.Forms", "System.Drawing")
}
# </PfControlLibrary>

function New-GuiFont {
    param(
        [string]$Family = "Segoe UI",
        [single]$Size = 9.5,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )

    foreach ($candidate in @($Family, "Exo 2", "Segoe UI", "Arial")) {
        try {
            return New-Object System.Drawing.Font($candidate, $Size, $Style)
        } catch {
            continue
        }
    }

    return New-Object System.Drawing.Font([System.Drawing.FontFamily]::GenericSansSerif, $Size, $Style)
}

function New-GuiChromePanel {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$Tag = "ChromePanel"
    )

    # PfCard est un Panel : .Controls, .SendToBack et le reste sont intacts.
    # Seul change le rendu - coins arrondis, bordure fine, pas de relief.
    Initialize-PfControlLibrary
    $panel = New-Object PokeFeur.Ui.PfCard
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($Width, $Height)
    $panel.Tag = $Tag
    return $panel
}

function New-ComboBox {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Name,
        [int]$X,
        [int]$Y,
        [int]$Width = 220
    )
    # PfComboBox EST une ComboBox : .Items, .SelectedIndex, .DisplayMember et
    # les evenements sont inchanges, seul le rendu differe.
    Initialize-PfControlLibrary
    $combo = New-Object PokeFeur.Ui.PfComboBox
    $combo.DropDownStyle = "DropDownList"
    $combo.Location = New-Object System.Drawing.Point($X, $Y)
    # La hauteur d'une ComboBox derive de ItemHeight : on la laisse decider.
    $combo.Width = $Width
    $Controls[$Name] = $combo
    return $combo
}

function New-CheckBox {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Name,
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 260,
        [bool]$Checked = $false,
        # Interrupteur plutot que case. Reserve aux fonctionnalites que le
        # module allume ou eteint : la forme dit la nature du reglage.
        [switch]$Toggle
    )
    Initialize-PfControlLibrary
    $check = if ($Toggle) {
        New-Object PokeFeur.Ui.PfToggle
    } else {
        New-Object PokeFeur.Ui.PfCheckBox
    }
    $check.Text = $Text
    $check.Checked = $Checked
    $check.Location = New-Object System.Drawing.Point($X, $Y)
    $check.Size = New-Object System.Drawing.Size($Width, 24)
    $check.AutoEllipsis = $true
    $Controls[$Name] = $check
    return $check
}

function New-Label {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 200,
        [int]$Height = 22
    )
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    Initialize-PfControlLibrary
    $label.Font = [PokeFeur.Ui.PfFont]::BodyBold
    $label.Tag = "InputLabel"
    $label.AutoEllipsis = $true
    return $label
}

function New-TextBox {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Name,
        [int]$X,
        [int]$Y,
        [int]$Width = 120,
        [string]$Text = ""
    )
    Initialize-PfControlLibrary
    $box = New-Object PokeFeur.Ui.PfTextBox
    $box.Location = New-Object System.Drawing.Point($X, $Y)
    $box.Size = New-Object System.Drawing.Size($Width, 24)
    $box.Text = $Text
    $Controls[$Name] = $box
    return $box
}

# Lecture tolerante d'un champ numerique de l'interface : du texte invalide
# doit retomber sur la valeur par defaut, pas faire echouer la generation.
function ConvertTo-BoundedInt {
    param(
        [string]$Text,
        [int]$Default = 0,
        [int]$Minimum = 0,
        [int]$Maximum = 5
    )

    $parsed = 0
    if (-not [int]::TryParse(([string]$Text).Trim(), [ref]$parsed)) {
        return $Default
    }
    if ($parsed -lt $Minimum) { return $Minimum }
    if ($parsed -gt $Maximum) { return $Maximum }
    return $parsed
}

function Get-ComboValue {
    param([System.Windows.Forms.ComboBox]$Combo)
    if ($Combo.SelectedItem) {
        return $Combo.SelectedItem.Value
    }
    return ""
}

function Set-ComboValue {
    param(
        [System.Windows.Forms.ComboBox]$Combo,
        [string]$Value
    )

    if (-not $Combo) {
        return $false
    }

    for ($i = 0; $i -lt $Combo.Items.Count; $i++) {
        if ([string]$Combo.Items[$i].Value -eq [string]$Value) {
            $Combo.SelectedIndex = $i
            return $true
        }
    }
    return $false
}

function Get-GuiPresetOptionNames {
    return [string[]]@(
        "GameVersion",
        "Seed",
        "UiLanguage",
        "ReportLanguage",
        "GuiTheme",
        "DisableExpShare",
        "RuntimePcControls",
        "GymLeagueStoryLevelCap",
        "AutoInstallToEden",
        "EdenModName",
        "InstallToRyujinx",
        "ExportEncounterZoneReport",
        "TrainerSpeciesMode",
        "TrainerMoveMode",
        "TrainerSmogonMoveFallbackMode",
        "TrainerItemMode",
        "TrainerItemPoolMode",
        "TrainerAddedSlotSpeciesMode",
        "TrainerDuplicateMode",
        "TrainerAbilityMode",
        "TrainerIVMode",
        "TrainerEVMode",
        "TrainerNatureMode",
        "RandomizeTrainerNatures",
        "TrainerLevelMultiplier",
        "TrainerTeamMin",
        "TrainerTeamMax",
        "TrainerTypeThemed",
        "TrainerShinyChancePercent",
        "ForceTrainerFullyEvolved",
        "TrainerFullyEvolvedLevel",
        "MaxTrainerAI",
        "TrainerDynamaxLevelMode",
        "ForceTrainerCanDynamax",
        "ForceAllTeamsToSix",
        "ForceBossTeamsToSix",
        "BossTeamsToSixScope",
        "AllowLegendaryTrainers",
        "TrainerExtraPokemonBoss",
        "TrainerExtraPokemonImportant",
        "TrainerExtraPokemonRegular",
        "TrainerSpecialRuleScope",
        "TrainerLegendaryPolicy",
        "TrainerMinBaseStatTotal",
        "TrainerForceDiverseTypes",
        "TypeMode",
        "TypesMonotypeOnly",
        "AbilityMode",
        "AllowWonderGuard",
        "StatMode",
        "ExpYieldMultiplier",
        "ForceOneExpYield",
        "RandomizeMoveTypes",
        "RandomizeMovePower",
        "MovePowerMin",
        "MovePowerMax",
        "RandomizeMovePP",
        "MovePPMin",
        "MovePPMax",
        "RandomizeMoveAccuracy",
        "MoveAccuracyMin",
        "MoveAccuracyMax",
        "RandomizeMoveCategory",
        "RandomizePickupItems",
        "RandomizeShopItems",
        "ShopPriceMultiplier",
        "RandomizeFieldItems",
        "RandomizeHiddenItems",
        "FieldItemPoolMode",
        "ModOverworldShiny",
        "OverworldShinyBoostPercent",
        "ModUncapLevel",
        "ModUnderworld",
        "ModExtendedFollowing",
        "ModGlimwoodOverworld",
        "GlimwoodMaxSpawns",
        "ModFishingTweaks",
        "ModDexAnimations",
        "TmMoveMode",
        "LearnsetMoveMode",
        "ModSynchroMode",
        "ModCameraTweaks",
        "ModFreecam",
        "EvolutionForceGrowth",
        "EvolutionSameType",
        "FollowEvolutionsForTypes",
        "FollowEvolutionsForAbilities",
        "EvolutionLimitToThreeStages",
        "StarterMinBaseStatTotal",
        "StarterMaxBaseStatTotal",
        "MinimumCatchRate",
        "ExpCurveMode",
        "TmCompatibilityMode",
        "TutorCompatibilityMode",
        "RandomizeWildHeldItems",
        "RandomizeTechnicalRecords",
        "EvolutionMode",
        "AllowLegendaryEvolutions",
        "NormalizeFriendshipEvolutions",
        "FriendshipEvolutionLevel",
        "NormalizeTradeEvolutions",
        "TradeEvolutionLevel",
        "NormalizeSpecialEvolutions",
        "SpecialEvolutionLevel",
        "GiftMode",
        "NpcGiftItemMode",
        "StarterMode",
        "Starter1",
        "Starter2",
        "Starter3",
        "PatchStarterRelatedTrainers",
        "AllowLegendaryGifts",
        "TradeMode",
        "AllowLegendaryTrades",
        "StaticEncounterMode",
        "AllowLegendaryStaticEncounters",
        "StaticEncounterStableMapping",
        "GrassEncounterMode",
        "AllowLegendaryGrassEncounters",
        "GrassEncounterStableMapping",
        "VisibleEncounterBehavior",
        "EncounterDrawMode",
        "LiveVisibleMode",
        "LiveBattleMode",
        "AllowLegendaryLiveVisible",
        "AllowLegendaryLiveBattle",
        "LiveGenerationFilter",
        "OverworldVisiblePoolMode",
        "OverworldVisibleMaxHitbox",
        "WildLevelPercent",
        "UndergroundMode",
        "AllowLegendaryUnderground",
        # Ces neuf-la manquaient : les controles existaient, etaient lus au
        # lancement, mais n'etaient jamais ecrits dans le preset. Un import les
        # remettait donc silencieusement a leur valeur par defaut.
        "WriteInstallationPackage",
        "StrictDataFiles",
        "TrainerBagItemMode",
        "ShopItemMode",
        "EvolutionMinBstGain",
        "GenerationFilterVisible",
        "GenerationFilterBattle",
        "GenerationFilterGifts",
        "GenerationFilterTrainers"
    )
}

function Get-GuiPresetLocalPathOptionNames {
    return [string[]]@(
        "Source",
        "SourceExefs",
        "Output"
    )
}

function Get-GuiPresetFromControls {
    param([System.Collections.Hashtable]$Controls)

    $options = [ordered]@{}
    foreach ($name in Get-GuiPresetOptionNames) {
        if (-not $Controls.ContainsKey($name)) {
            continue
        }

        $control = $Controls[$name]
        if ($control -is [System.Windows.Forms.ComboBox]) {
            $options[$name] = Get-ComboValue -Combo $control
        } elseif ($control -is [System.Windows.Forms.CheckBox]) {
            $options[$name] = [bool]$control.Checked
        } elseif ($control -is [System.Windows.Forms.TextBox]) {
            $options[$name] = [string]$control.Text
        }
    }

    return [pscustomobject][ordered]@{
        presetVersion = "PokeFeurRandomSWSH.GuiPreset.V1"
        appVersion = $AppVersion
        exportedAt = (Get-Date).ToString("o")
        options = $options
    }
}

function Set-GuiControlsFromPreset {
    param(
        [System.Collections.Hashtable]$Controls,
        [object]$Preset
    )

    if ($null -eq $Preset) {
        throw "Preset JSON vide."
    }

    $options = if ($Preset.PSObject.Properties.Name -contains "options") { $Preset.options } else { $Preset }
    if ($null -eq $options) {
        throw "Preset JSON invalide: bloc options introuvable."
    }

    $script:LastPresetSkippedPathOptions = @()
    foreach ($pathName in Get-GuiPresetLocalPathOptionNames) {
        if ($options.PSObject.Properties.Name -contains $pathName) {
            $pathValue = [string]$options.$pathName
            if (-not [string]::IsNullOrWhiteSpace($pathValue)) {
                $script:LastPresetSkippedPathOptions += ("{0}={1}" -f $pathName, $pathValue)
            }
        }
    }

    $applied = 0
    foreach ($name in Get-GuiPresetOptionNames) {
        if (-not $Controls.ContainsKey($name)) {
            continue
        }
        if (-not ($options.PSObject.Properties.Name -contains $name)) {
            continue
        }

        $control = $Controls[$name]
        $value = $options.$name
        if ($control -is [System.Windows.Forms.ComboBox]) {
            if ($name -eq "VisibleEncounterBehavior") {
                $value = Get-NormalizedVisibleEncounterBehavior -Value ([string]$value)
            }
            # Ancien preset ecrit avant le retrait de l'entree en double : le
            # mode "Random" donnait deja exactement le meme resultat que "Slot".
            if (($name -eq "GrassEncounterStableMapping" -or $name -eq "StaticEncounterStableMapping") -and
                (Normalize-StableMappingMode -Value ([string]$value)) -eq "random") {
                $value = "Slot"
            }
            if (Set-ComboValue -Combo $control -Value ([string]$value)) {
                $applied++
            }
        } elseif ($control -is [System.Windows.Forms.CheckBox]) {
            $control.Checked = [System.Convert]::ToBoolean($value)
            $applied++
        } elseif ($control -is [System.Windows.Forms.TextBox]) {
            if ($name -eq "Output") {
                $control.Text = Get-OutputPackageRoot -OutputRomfsRoot ([string]$value)
            } else {
                $control.Text = [string]$value
            }
            $applied++
        }
    }

    if (
        $Controls.ContainsKey("EncounterDrawMode") -and
        -not ($options.PSObject.Properties.Name -contains "EncounterDrawMode") -and
        ($options.PSObject.Properties.Name -contains "VisibleEncounterBehavior")
    ) {
        $legacyDrawMode = Get-NormalizedEncounterDrawMode -Value "" -LegacyVisibleBehavior ([string]$options.VisibleEncounterBehavior)
        if (Set-ComboValue -Combo $Controls.EncounterDrawMode -Value $legacyDrawMode) {
            $applied++
        }
    }

    if ($applied -lt 1) {
        throw "Preset JSON invalide: aucune option reconnue."
    }

    if (
        $Controls.ContainsKey("TrainerNatureMode") -and
        -not ($options.PSObject.Properties.Name -contains "TrainerNatureMode") -and
        ($options.PSObject.Properties.Name -contains "RandomizeTrainerNatures") -and
        [System.Convert]::ToBoolean($options.RandomizeTrainerNatures)
    ) {
        if (Set-ComboValue -Combo $Controls.TrainerNatureMode -Value "Random") {
            $applied++
        }
    }

    return $applied
}

function Set-GuiControlValue {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Name,
        [object]$Value
    )

    if (-not $Controls.ContainsKey($Name)) {
        return $false
    }

    $control = $Controls[$Name]
    if ($control -is [System.Windows.Forms.ComboBox]) {
        if ($Name -eq "VisibleEncounterBehavior") {
            $Value = Get-NormalizedVisibleEncounterBehavior -Value ([string]$Value)
        }
        return (Set-ComboValue -Combo $control -Value ([string]$Value))
    }
    if ($control -is [System.Windows.Forms.CheckBox]) {
        $control.Checked = [System.Convert]::ToBoolean($Value)
        return $true
    }
    if ($control -is [System.Windows.Forms.TextBox]) {
        $control.Text = [string]$Value
        return $true
    }

    return $false
}

function Try-ParseInvariantDouble {
    param(
        [string]$Text,
        [ref]$Value
    )

    $styles = [System.Globalization.NumberStyles]::Float
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $normalized = ([string]$Text).Trim().Replace(",", ".")
    return [double]::TryParse($normalized, $styles, $culture, $Value)
}

function Convert-GuiDoubleText {
    param(
        [string]$Text,
        [string]$Label,
        [string]$Language = "fr"
    )

    $value = 0.0
    if (-not (Try-ParseInvariantDouble -Text $Text -Value ([ref]$value))) {
        if ($Language -eq "en") {
            throw "$Label must be numeric."
        }
        throw "$Label doit etre numerique."
    }
    return $value
}

function Test-GuiBuildConfiguration {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Language = "fr"
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $infos = New-Object System.Collections.Generic.List[string]

    $addError = { param([string]$Message) [void]$errors.Add($Message) }
    $addWarning = { param([string]$Message) [void]$warnings.Add($Message) }
    $addInfo = { param([string]$Message) [void]$infos.Add($Message) }

    $textOf = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.TextBox]) {
            return ([string]$Controls[$Name].Text).Trim()
        }
        return ""
    }
    $checkedOf = {
        param([string]$Name)
        return ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.CheckBox] -and [bool]$Controls[$Name].Checked)
    }
    $comboOf = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.ComboBox]) {
            return [string](Get-ComboValue -Combo $Controls[$Name])
        }
        return ""
    }

    $sourceRomfs = ""
    $sourceExefs = ""
    $outputPackage = ""
    $sourceRomfsText = & $textOf "Source"
    $sourceExefsText = & $textOf "SourceExefs"
    $outputText = & $textOf "Output"
    $gameVersion = & $comboOf "GameVersion"

    try {
        $sourceRomfs = Resolve-RequiredSourceRomfsRoot -SourceRomfsRoot $sourceRomfsText
        Assert-ValidSourceRomfsForRandomizer -RomfsRoot $sourceRomfs
        & $addInfo $(if ($lang -eq "en") { "ROMFS source OK: $sourceRomfs" } else { "Source ROMFS OK: $sourceRomfs" })
    } catch {
        & $addError $_.Exception.Message
    }

    if ([string]::IsNullOrWhiteSpace($outputText)) {
        & $addError $(if ($lang -eq "en") { "Generated mod folder is required." } else { "Dossier du mod généré obligatoire." })
    } else {
        try {
            $outputPackage = Get-OutputPackageRoot -OutputRomfsRoot $outputText
            [void](Resolve-OutputRomfsRoot -OutputPath $outputText)
            if (-not [string]::IsNullOrWhiteSpace($sourceRomfs)) {
                if (Test-PathInsideRoot -Path $outputPackage -Root $sourceRomfs) {
                    & $addError $(if ($lang -eq "en") { "Output cannot be inside the source ROMFS folder." } else { "La sortie ne peut pas être dans le dossier ROMFS source." })
                }
                if (Test-PathInsideRoot -Path $sourceRomfs -Root $outputPackage) {
                    & $addError $(if ($lang -eq "en") { "Source ROMFS cannot be inside the generated output folder." } else { "Le ROMFS source ne peut pas être dans le dossier de sortie généré." })
                }
            }
            & $addInfo $(if ($lang -eq "en") { "Output root OK: $outputPackage" } else { "Dossier de sortie OK: $outputPackage" })
        } catch {
            & $addError $_.Exception.Message
        }
    }

    $seedText = & $textOf "Seed"
    $seedValue = 0L
    if (-not [long]::TryParse($seedText, [ref]$seedValue)) {
        & $addError $(if ($lang -eq "en") { "Seed must be a numeric integer. Use -1 for auto." } else { "Le seed doit être un entier numérique. Utilise -1 pour auto." })
    }

    $needsRuntime = $false
    $runtimeReasons = New-Object System.Collections.Generic.List[string]
    $visibleBehavior = Get-NormalizedVisibleEncounterBehavior -Value (& $comboOf "VisibleEncounterBehavior")
    $expMultiplier = 1.0
    [void](Try-ParseInvariantDouble -Text (& $textOf "ExpYieldMultiplier") -Value ([ref]$expMultiplier))
    if (& $checkedOf "RuntimePcControls") { $needsRuntime = $true; [void]$runtimeReasons.Add("PC runtime") }
    if (& $checkedOf "DisableExpShare") { $needsRuntime = $true; [void]$runtimeReasons.Add("EXP Share runtime") }
    if (& $checkedOf "EarlyBike") { $needsRuntime = $true; [void]$runtimeReasons.Add("early bike") }
    if (& $checkedOf "DynamicExpLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("dynamic EXP cap") }
    if (& $checkedOf "StrictBossMaxLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("strict boss EXP cap") }
    if (& $checkedOf "MainStorySoftLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("soft story EXP cap") }
    if (& $checkedOf "GymLeagueStoryLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("gym/champion EXP cap") }
    if (& $checkedOf "StoryMajorBattleOrderLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("ordered major battle EXP cap") }
    if ((-not (& $checkedOf "ForceOneExpYield")) -and [Math]::Abs($expMultiplier - 1.0) -gt 0.0001) { $needsRuntime = $true; [void]$runtimeReasons.Add("EXP boost") }
    if ($visibleBehavior -ne "RomfsMatch") { $needsRuntime = $true; [void]$runtimeReasons.Add("hidden visible battle runtime") }

    if ($needsRuntime) {
        if ([string]::IsNullOrWhiteSpace($sourceExefsText)) {
            & $addWarning $(if ($lang -eq "en") { "Runtime/ExLaunch options are enabled, but no ExeFS folder was explicitly provided. The build will stay ROMFS-only and will not generate exefs or sdmc." } else { "Des options runtime/ExLaunch sont actives, mais aucun dossier ExeFS n'a été explicitement fourni. La génération restera en mode ROMFS-only et ne produira ni exefs ni sdmc." })
        } else {
            try {
                $sourceExefs = Resolve-RequiredSourceExefsRoot -SourceRomfsRoot $sourceRomfsText -SourceExefsRoot $sourceExefsText -GameVersion $gameVersion
                & $addInfo $(if ($lang -eq "en") { "ExeFS source OK for runtime features: $sourceExefs" } else { "Source ExeFS OK pour les options runtime: $sourceExefs" })
            } catch {
                & $addError $_.Exception.Message
            }
        }
    } elseif (-not [string]::IsNullOrWhiteSpace($sourceExefsText)) {
        try {
            $sourceExefs = Resolve-SourceExefsRoot -SourceRomfsRoot $sourceRomfsText -SourceExefsRoot $sourceExefsText -GameVersion $gameVersion
            if (-not [string]::IsNullOrWhiteSpace($sourceExefs)) {
                & $addInfo $(if ($lang -eq "en") { "ExeFS source detected: $sourceExefs" } else { "Source ExeFS détectée: $sourceExefs" })
            }
        } catch {
            & $addWarning $_.Exception.Message
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($sourceExefs) -and -not [string]::IsNullOrWhiteSpace($outputPackage)) {
        if (Test-PathInsideRoot -Path $outputPackage -Root $sourceExefs) {
            & $addError $(if ($lang -eq "en") { "Output cannot be inside the source ExeFS folder." } else { "La sortie ne peut pas être dans le dossier ExeFS source." })
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($sourceRomfs)) {
        $requiredFiles = New-Object System.Collections.Generic.HashSet[string]
        $requiredDirs = New-Object System.Collections.Generic.HashSet[string]
        [void]$requiredFiles.Add("bin\pml\personal\personal_total.bin")
        [void]$requiredDirs.Add("bin\trainer\trainer_data")
        [void]$requiredDirs.Add("bin\trainer\trainer_poke")

        $trainerMoveMode = Normalize-Mode (& $comboOf "TrainerMoveMode")
        $smogonFallback = Normalize-Mode (& $comboOf "TrainerSmogonMoveFallbackMode")
        if ($trainerMoveMode -eq "lastlevelup4" -or ((Test-TrainerModeUsesSmogon $trainerMoveMode) -and $smogonFallback -eq "lastlevelup4")) {
            [void]$requiredFiles.Add("bin\pml\waza_oboe\wazaoboe_total.bin")
        }
        if ($trainerMoveMode -eq "random4" -or (Test-TrainerModeUsesSmogon $trainerMoveMode) -or (& $checkedOf "RandomizeMoveTypes") -or (& $checkedOf "RandomizeMovePower") -or (& $checkedOf "RandomizeMovePP") -or (& $checkedOf "RandomizeMoveAccuracy") -or (& $checkedOf "RandomizeMoveCategory")) {
            [void]$requiredDirs.Add("bin\pml\waza")
        }
        if ((Normalize-Mode (& $comboOf "EvolutionMode")) -ne "unchanged" -or (& $checkedOf "NormalizeFriendshipEvolutions") -or (& $checkedOf "NormalizeTradeEvolutions") -or (& $checkedOf "NormalizeSpecialEvolutions") -or (& $checkedOf "ForceTrainerFullyEvolved")) {
            [void]$requiredDirs.Add("bin\pml\evolution")
        }
        if ((Normalize-Mode (& $comboOf "GiftMode")) -ne "unchanged" -or (Normalize-Mode (& $comboOf "StarterMode")) -ne "unchanged" -or -not [string]::IsNullOrWhiteSpace((& $textOf "Starter1") + (& $textOf "Starter2") + (& $textOf "Starter3"))) {
            [void]$requiredFiles.Add("bin\script_event_data\add_poke.bin")
        }
        if ((Normalize-Mode (& $comboOf "TradeMode")) -ne "unchanged") {
            [void]$requiredFiles.Add("bin\script_event_data\field_trade.bin")
        }
        if ((Normalize-Mode (& $comboOf "StaticEncounterMode")) -ne "unchanged") {
            [void]$requiredFiles.Add("bin\script_event_data\event_encount_data.bin")
        }
        if ((Normalize-Mode (& $comboOf "GrassEncounterMode")) -ne "unchanged" -or $visibleBehavior -ne "RomfsMatch") {
            [void]$requiredFiles.Add("bin\archive\field\resident\data_table.gfpak")
        }
        if ((Normalize-Mode (& $comboOf "UndergroundMode")) -ne "unchanged") {
            [void]$requiredFiles.Add("bin\appli\chika\data_table\underground_exploration_poke.bin")
        }
        if (& $checkedOf "RuntimePcControls") {
            [void]$requiredFiles.Add("bin\script\param\script_id\script_id_record.bin")
        }

        foreach ($relativeDir in @($requiredDirs)) {
            if (-not (Test-Path -LiteralPath (Join-Path $sourceRomfs $relativeDir) -PathType Container)) {
                & $addError $(if ($lang -eq "en") { "Missing required ROMFS folder: $relativeDir" } else { "Dossier ROMFS requis manquant: $relativeDir" })
            }
        }
        foreach ($relativeFile in @($requiredFiles)) {
            $path = Join-Path $sourceRomfs $relativeFile
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                & $addError $(if ($lang -eq "en") { "Missing required ROMFS file: $relativeFile" } else { "Fichier ROMFS requis manquant: $relativeFile" })
            } elseif ((Get-Item -LiteralPath $path).Length -le 0) {
                & $addError $(if ($lang -eq "en") { "Required ROMFS file is empty: $relativeFile" } else { "Fichier ROMFS requis vide: $relativeFile" })
            }
        }
    }

    $validateDouble = {
        param([string]$Name, [string]$Label, [double]$Min, [double]$Max)
        $value = 0.0
        if (-not (Try-ParseInvariantDouble -Text (& $textOf $Name) -Value ([ref]$value))) {
            & $addError $(if ($lang -eq "en") { "$Label must be numeric." } else { "$Label doit être numérique." })
            return $null
        }
        if ($value -lt $Min -or $value -gt $Max) {
            & $addError $(if ($lang -eq "en") { "$Label must be between $Min and $Max." } else { "$Label doit être entre $Min et $Max." })
        }
        return $value
    }
    $validateInt = {
        param([string]$Name, [string]$Label, [int]$Min, [int]$Max, [bool]$AllowMinusOne)
        $value = 0
        if (-not [int]::TryParse((& $textOf $Name), [ref]$value)) {
            & $addError $(if ($lang -eq "en") { "$Label must be an integer." } else { "$Label doit être un entier." })
            return $null
        }
        if ($AllowMinusOne -and $value -eq -1) {
            return $value
        }
        if ($value -lt $Min -or $value -gt $Max) {
            & $addError $(if ($lang -eq "en") { "$Label must be between $Min and $Max." } else { "$Label doit être entre $Min et $Max." })
        }
        return $value
    }

    $levelMult = & $validateDouble "TrainerLevelMultiplier" $(if ($lang -eq "en") { "Trainer level multiplier" } else { "Multiplicateur des niveaux" }) 0.1 10.0
    if ($levelMult -and $levelMult -gt 3.0) {
        & $addWarning $(if ($lang -eq "en") { "Trainer level multiplier is very high; many teams may clamp to Lv.100." } else { "Le multiplicateur de niveau est très haut; beaucoup d'équipes peuvent finir bloquees au niveau 100." })
    }
    $teamMin = & $validateInt "TrainerTeamMin" $(if ($lang -eq "en") { "Minimum team size" } else { "Taille équipe minimum" }) 1 6 $true
    $teamMax = & $validateInt "TrainerTeamMax" $(if ($lang -eq "en") { "Maximum team size" } else { "Taille équipe maximum" }) 1 6 $true
    if ($null -ne $teamMin -and $null -ne $teamMax -and $teamMin -ne -1 -and $teamMax -ne -1 -and $teamMin -gt $teamMax) {
        & $addError $(if ($lang -eq "en") { "Minimum team size cannot be higher than maximum team size." } else { "La taille équipe minimum ne peut pas être supérieure au maximum." })
    }
    [void](& $validateDouble "TrainerShinyChancePercent" $(if ($lang -eq "en") { "Trainer shiny rate" } else { "Taux shiny dresseurs" }) 0.0 100.0)
    [void](& $validateInt "TrainerFullyEvolvedLevel" $(if ($lang -eq "en") { "Final evolution level" } else { "Niveau évolution finale" }) 1 100 $false)
    # Plafond porte a 100 : le module applique la valeur telle quelle
    # (ApplyRuntimeMultiplier), seul le bouton Y du PC est limite a ses cinq
    # paliers compiles 1, 2, 5, 10, 25.
    [void](& $validateDouble "ExpYieldMultiplier" $(if ($lang -eq "en") { "EXP yield multiplier" } else { "Multiplicateur EXP" }) 0.01 100.0)
    [void](& $validateInt "MovePowerMin" $(if ($lang -eq "en") { "Move power min" } else { "Puissance min" }) 1 250 $false)
    $movePowerMax = & $validateInt "MovePowerMax" $(if ($lang -eq "en") { "Move power max" } else { "Puissance max" }) 1 250 $false
    $movePowerMin = 0
    [void][int]::TryParse((& $textOf "MovePowerMin"), [ref]$movePowerMin)
    if ($movePowerMax -and $movePowerMin -gt $movePowerMax) {
        & $addError $(if ($lang -eq "en") { "Move power min cannot be higher than move power max." } else { "La puissance min ne peut pas être supérieure a la puissance max." })
    }
    [void](& $validateInt "MovePPMin" $(if ($lang -eq "en") { "Move PP min" } else { "PP min" }) 1 64 $false)
    $movePPMax = & $validateInt "MovePPMax" $(if ($lang -eq "en") { "Move PP max" } else { "PP max" }) 1 64 $false
    $movePPMin = 0
    [void][int]::TryParse((& $textOf "MovePPMin"), [ref]$movePPMin)
    if ($movePPMax -and $movePPMin -gt $movePPMax) {
        & $addError $(if ($lang -eq "en") { "Move PP min cannot be higher than move PP max." } else { "Les PP min ne peuvent pas être superieurs aux PP max." })
    }
    [void](& $validateInt "MoveAccuracyMin" $(if ($lang -eq "en") { "Move accuracy min" } else { "Précision min" }) 1 100 $false)
    $moveAccuracyMax = & $validateInt "MoveAccuracyMax" $(if ($lang -eq "en") { "Move accuracy max" } else { "Précision max" }) 1 100 $false
    $moveAccuracyMin = 0
    [void][int]::TryParse((& $textOf "MoveAccuracyMin"), [ref]$moveAccuracyMin)
    if ($moveAccuracyMax -and $moveAccuracyMin -gt $moveAccuracyMax) {
        & $addError $(if ($lang -eq "en") { "Move accuracy min cannot be higher than move accuracy max." } else { "La précision min ne peut pas être supérieure à la précision max." })
    }

    if ((& $checkedOf "ForceOneExpYield") -and [Math]::Abs($expMultiplier - 1.0) -gt 0.0001) {
        & $addWarning $(if ($lang -eq "en") { "No EXP mode overrides the EXP multiplier; the multiplier will not matter." } else { "Le mode No EXP prend le dessus sur le multiplicateur EXP; le multiplicateur ne servira pas." })
    }
    if ((& $checkedOf "ForceAllTeamsToSix") -and (& $checkedOf "ForceBossTeamsToSix")) {
        & $addWarning $(if ($lang -eq "en") { "All teams at 6 already includes boss teams; the boss-only option is redundant." } else { "Mettre tous les dresseurs à 6 inclut déjà les boss : l'option boss seulement est redondante." })
    }
    if ((Normalize-Mode (& $comboOf "TrainerSpeciesMode")) -eq "unchanged" -and (& $checkedOf "TrainerTypeThemed")) {
        & $addWarning $(if ($lang -eq "en") { "Type-themed trainer teams only matters when trainer species are randomized." } else { "Les équipes themees par type servent surtout quand les espèces des dresseurs sont randomisées." })
    }
    if ((Normalize-Mode (& $comboOf "TrainerItemMode")) -eq "removeall") {
        & $addWarning $(if ($lang -eq "en") { "Held item pool is ignored because held items are removed." } else { "Le pool d'objets est ignore car les objets tenus sont supprimes." })
    }
    $validationUsesSmogon = (Test-TrainerModeUsesSmogon (& $comboOf "TrainerMoveMode")) -or (Test-TrainerModeUsesSmogon (& $comboOf "TrainerItemMode")) -or (Test-TrainerModeUsesSmogon (& $comboOf "TrainerAbilityMode")) -or (Test-TrainerModeUsesSmogon (& $comboOf "TrainerEVMode")) -or (Test-TrainerModeUsesSmogon (& $comboOf "TrainerNatureMode"))
    $validationUsesLegacySmogon = (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerMoveMode")) -or (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerItemMode")) -or (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerAbilityMode")) -or (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerEVMode")) -or (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerNatureMode"))
    if ($validationUsesSmogon) {
        & $addInfo $(if ($lang -eq "en") { "Smogon strategic modes use one coherent cached set per Pokemon when present, then fall back to safe local choices if a set is missing." } else { "Les modes Stratégique Smogon utilisent un même set cohérent en cache par Pokémon quand il existe, puis un backup propre si un set manque." })
    }
    if ($validationUsesLegacySmogon) {
        & $addInfo $(if ($lang -eq "en") { "Smogon historical mode tries SS first, then SM, XY, BW, DP, RS, GS and RB; if no set exists, the configured backup is used." } else { "Le mode Smogon anciennes gens essaie SS d'abord, puis SM, XY, BW, DP, RS, GS et RB; si aucun set n'existe, le backup configure est utilise." })
    }
    if ($needsRuntime) {
        & $addInfo $(if ($lang -eq "en") { "Runtime features enabled: $($runtimeReasons -join ', ')." } else { "Options runtime actives: $($runtimeReasons -join ', ')." })
    }
    if ((& $checkedOf "AutoInstallToEden") -and -not (& $checkedOf "InstallToRyujinx")) {
        & $addError $(if ($lang -eq "en") { "Auto-install is enabled but no emulator target is selected." } else { "L'installation auto est activée mais aucune cible émulateur n'est cochee." })
    }

    return [pscustomobject]@{
        Errors = $errors
        Warnings = $warnings
        Infos = $infos
    }
}

function Format-GuiBuildValidationResult {
    param(
        [object]$Validation,
        [string]$Language = "fr"
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $lines = New-Object System.Collections.Generic.List[string]
    if ($Validation.Errors.Count -eq 0 -and $Validation.Warnings.Count -eq 0) {
        [void]$lines.Add($(if ($lang -eq "en") { "Validation OK: the build can start." } else { "Validation OK: la génération peut demarrer." }))
    } else {
        [void]$lines.Add($(if ($lang -eq "en") { "Validation result:" } else { "Résultat de validation:" }))
    }
    foreach ($message in @($Validation.Errors)) {
        [void]$lines.Add("ERREUR: $message")
    }
    foreach ($message in @($Validation.Warnings)) {
        [void]$lines.Add($(if ($lang -eq "en") { "WARNING: $message" } else { "AVERTISSEMENT: $message" }))
    }
    foreach ($message in @($Validation.Infos | Select-Object -First 8)) {
        [void]$lines.Add("OK: $message")
    }
    return ($lines -join [Environment]::NewLine)
}

function Confirm-GuiBuildValidationResult {
    param(
        [System.Windows.Forms.Form]$Owner,
        [object]$Validation,
        [string]$Language = "fr",
        [bool]$ConfirmWarnings = $true
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $text = Format-GuiBuildValidationResult -Validation $Validation -Language $lang
    if ($Validation.Errors.Count -gt 0) {
        $title = if ($lang -eq "en") { "Build blocked" } else { "Génération bloquee" }
        [void][System.Windows.Forms.MessageBox]::Show($Owner, $text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    if ($ConfirmWarnings -and $Validation.Warnings.Count -gt 0) {
        $title = if ($lang -eq "en") { "Continue with warnings?" } else { "Continuer avec avertissements ?" }
        $question = if ($lang -eq "en") { "$text`r`n`r`nContinue generation anyway?" } else { "$text`r`n`r`nContinuer la génération quand même ?" }
        $answer = [System.Windows.Forms.MessageBox]::Show($Owner, $question, $title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return ($answer -eq [System.Windows.Forms.DialogResult]::Yes)
    }
    return $true
}

function Test-IsPipelineStoppedException {
    param([object]$Exception)

    $current = $Exception
    while ($null -ne $current) {
        $typeName = $current.GetType().FullName
        if ($typeName -eq "System.Management.Automation.PipelineStoppedException") {
            return $true
        }
        $current = $current.InnerException
    }
    return $false
}

function Get-GuiBuildSummaryText {
    param(
        [System.Collections.Hashtable]$Controls,
        [object]$Validation = $null,
        [string]$Language = "fr"
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $lines = New-Object System.Collections.Generic.List[string]
    $changed = 0

    $textOf = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.TextBox]) {
            return ([string]$Controls[$Name].Text).Trim()
        }
        return ""
    }
    $checkedOf = {
        param([string]$Name)
        return ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.CheckBox] -and [bool]$Controls[$Name].Checked)
    }
    $comboValue = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.ComboBox]) {
            return [string](Get-ComboValue -Combo $Controls[$Name])
        }
        return ""
    }
    $comboLabel = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.ComboBox] -and $Controls[$Name].SelectedItem) {
            return [string]$Controls[$Name].SelectedItem.Label
        }
        return (& $comboValue $Name)
    }
    $yesNo = {
        param([bool]$Value)
        if ($lang -eq "en") {
            return $(if ($Value) { "YES" } else { "NO" })
        }
        return $(if ($Value) { "OUI" } else { "NON" })
    }
    $addLine = {
        param([string]$Text = "")
        [void]$lines.Add($Text)
    }
    $addSection = {
        param([string]$Title)
        & $addLine ""
        & $addLine ("=== {0} ===" -f $Title)
    }
    $addChange = {
        param(
            [string]$Label,
            [string]$Value
        )
        if (-not [string]::IsNullOrWhiteSpace($Label) -and -not [string]::IsNullOrWhiteSpace($Value)) {
            [void]$lines.Add(("- {0}: {1}" -f $Label, $Value))
            $script:GuiBuildSummaryChangedCount++
        }
    }
    $addIfComboChanged = {
        param(
            [string]$Name,
            [string]$Label,
            [string[]]$UnchangedValues = @("Unchanged")
        )
        $value = & $comboValue $Name
        if (-not [string]::IsNullOrWhiteSpace($value) -and ($UnchangedValues -notcontains $value)) {
            & $addChange $Label (& $comboLabel $Name)
        }
    }
    $addIfChecked = {
        param(
            [string]$Name,
            [string]$Label,
            [string]$Value = ""
        )
        if (& $checkedOf $Name) {
            if ([string]::IsNullOrWhiteSpace($Value)) {
                $Value = & $yesNo $true
            }
            & $addChange $Label $Value
        }
    }

    $script:GuiBuildSummaryChangedCount = 0
    $title = if ($lang -eq "en") { "What will be modified" } else { "Ce qui va être modifie" }
    & $addLine $title
    & $addLine ("=" * $title.Length)

    & $addSection $(if ($lang -eq "en") { "Source and output" } else { "Source et sortie" })
    & $addChange $(if ($lang -eq "en") { "Target game" } else { "Jeu cible" }) (& $comboLabel "GameVersion")
    & $addChange "ROMFS" (& $textOf "Source")
    & $addChange "ExeFS" (& $textOf "SourceExefs")
    & $addChange $(if ($lang -eq "en") { "Generated mod folder" } else { "Dossier généré" }) (& $textOf "Output")
    & $addChange "Seed" (& $textOf "Seed")

    & $addSection $(if ($lang -eq "en") { "Runtime / ExLaunch" } else { "Runtime / ExLaunch" })
    & $addIfChecked "DisableExpShare" $(if ($lang -eq "en") { "Default EXP Share" } else { "EXP Share par défaut" }) "OFF"
    & $addIfChecked "RuntimePcControls" $(if ($lang -eq "en") { "Pokemon Center PC menu" } else { "Menu PC Centre Pokémon" }) $(if ($lang -eq "en") { "runtime toggles enabled" } else { "options modifiables en jeu" })
    & $addIfChecked "GymLeagueStoryLevelCap" $(if ($lang -eq "en") { "Gym/Champion EXP cap" } else { "Cap EXP arènes/Tarak" }) $(if ($lang -eq "en") { "enabled" } else { "active" })
    $expMultiplierText = & $textOf "ExpYieldMultiplier"
    $expMultiplierValue = 1.0
    if ((Try-ParseInvariantDouble -Text $expMultiplierText -Value ([ref]$expMultiplierValue)) -and [Math]::Abs($expMultiplierValue - 1.0) -gt 0.0001 -and -not (& $checkedOf "ForceOneExpYield")) {
        & $addChange $(if ($lang -eq "en") { "Runtime EXP boost" } else { "Boost EXP runtime" }) ("x{0}" -f $expMultiplierValue.ToString("0.##", [System.Globalization.CultureInfo]::InvariantCulture))
    }
    $visibleBehavior = Get-NormalizedVisibleEncounterBehavior -Value (& $comboValue "VisibleEncounterBehavior")
    if ($visibleBehavior -ne "RomfsMatch") {
        & $addChange $(if ($lang -eq "en") { "Visible Pokemon runtime" } else { "Pokémon visibles runtime" }) (& $comboLabel "VisibleEncounterBehavior")
        & $addChange $(if ($lang -eq "en") { "Encounter draw mode" } else { "Mode de tirage rencontres" }) (& $comboLabel "EncounterDrawMode")
    }
    if ($script:GuiBuildSummaryChangedCount -le 6) {
        & $addLine $(if ($lang -eq "en") { "- No runtime option selected, unless another tab requires ExLaunch." } else { "- Aucune option runtime selectionnee, sauf si une autre option exige ExLaunch." })
    }

    & $addSection $(if ($lang -eq "en") { "Trainer battles" } else { "Combats de dresseurs" })
    & $addIfComboChanged "TrainerSpeciesMode" $(if ($lang -eq "en") { "Trainer Pokemon" } else { "Pokémon des dresseurs" })
    & $addIfComboChanged "TrainerMoveMode" $(if ($lang -eq "en") { "Trainer moves" } else { "Attaques des dresseurs" })
    if (Test-TrainerModeUsesSmogon (& $comboValue "TrainerMoveMode")) {
        & $addChange $(if ($lang -eq "en") { "Smogon move fallback" } else { "Attaques de secours Smogon" }) (& $comboLabel "TrainerSmogonMoveFallbackMode")
    }
    & $addIfComboChanged "TrainerItemMode" $(if ($lang -eq "en") { "Trainer held items" } else { "Objets tenus dresseurs" })
    if ((Normalize-Mode (& $comboValue "TrainerItemMode")) -in @("randomwhenpresent", "forceall") -or (Test-TrainerModeUsesSmogon (& $comboValue "TrainerItemMode"))) {
        & $addChange $(if ($lang -eq "en") { "Held item pool" } else { "Pool objets tenus" }) (& $comboLabel "TrainerItemPoolMode")
    }
    & $addIfComboChanged "TrainerAbilityMode" $(if ($lang -eq "en") { "Trainer abilities" } else { "Talents dresseurs" })
    & $addIfComboChanged "TrainerIVMode" "IV"
    & $addIfComboChanged "TrainerEVMode" "EV"
    $levelMultiplierText = & $textOf "TrainerLevelMultiplier"
    $levelMultiplierValue = 1.0
    if ((Try-ParseInvariantDouble -Text $levelMultiplierText -Value ([ref]$levelMultiplierValue)) -and [Math]::Abs($levelMultiplierValue - 1.0) -gt 0.0001) {
        & $addChange $(if ($lang -eq "en") { "Trainer level multiplier" } else { "Multiplicateur niveaux dresseurs" }) ("x{0}" -f $levelMultiplierValue.ToString("0.##", [System.Globalization.CultureInfo]::InvariantCulture))
    }
    if ((& $textOf "TrainerTeamMin") -ne "-1" -or (& $textOf "TrainerTeamMax") -ne "-1") {
        & $addChange $(if ($lang -eq "en") { "Trainer team size clamp" } else { "Limite taille équipes" }) ("min {0} / max {1}" -f (& $textOf "TrainerTeamMin"), (& $textOf "TrainerTeamMax"))
    }
    & $addIfChecked "ForceAllTeamsToSix" $(if ($lang -eq "en") { "All trainer teams" } else { "Toutes les équipes dresseurs" }) "6 Pokemon"
    if (& $checkedOf "ForceBossTeamsToSix") {
        & $addChange $(if ($lang -eq "en") { "Selected boss teams" } else { "Boss selectionnes" }) ("6 Pokemon - {0}" -f (& $comboLabel "BossTeamsToSixScope"))
        & $addChange $(if ($lang -eq "en") { "Added boss slots" } else { "Slots boss ajoutés" }) (& $comboLabel "TrainerAddedSlotSpeciesMode")
    }
    & $addChange $(if ($lang -eq "en") { "Team duplicate rule" } else { "Règle doublons équipes" }) (& $comboLabel "TrainerDuplicateMode")
    & $addIfChecked "TrainerTypeThemed" $(if ($lang -eq "en") { "Type-themed teams" } else { "Équipes themees par type" })
    & $addIfChecked "ForceTrainerFullyEvolved" $(if ($lang -eq "en") { "Force final evolutions" } else { "Forcer évolutions finales" }) ("Lv. {0}+" -f (& $textOf "TrainerFullyEvolvedLevel"))
    & $addIfComboChanged "TrainerNatureMode" $(if ($lang -eq "en") { "Trainer natures" } else { "Natures dresseurs" })
    & $addIfChecked "MaxTrainerAI" $(if ($lang -eq "en") { "Trainer AI" } else { "IA dresseurs" }) $(if ($lang -eq "en") { "maximum" } else { "maximum" })
    & $addIfComboChanged "TrainerDynamaxLevelMode" $(if ($lang -eq "en") { "Trainer Dynamax level" } else { "Niveau Dynamax dresseurs" })
    & $addIfChecked "ForceTrainerCanDynamax" $(if ($lang -eq "en") { "Trainer Dynamax flag" } else { "Flag CanDynamax dresseurs" })
    & $addIfChecked "AllowLegendaryTrainers" $(if ($lang -eq "en") { "Trainer legendary pool" } else { "Légendaires chez les dresseurs" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    $trainerShinyText = & $textOf "TrainerShinyChancePercent"
    $trainerShinyValue = 0.0
    if ((Try-ParseInvariantDouble -Text $trainerShinyText -Value ([ref]$trainerShinyValue)) -and $trainerShinyValue -gt 0.0) {
        & $addChange $(if ($lang -eq "en") { "Trainer shiny rate" } else { "Taux shiny dresseurs" }) ("{0}%" -f $trainerShinyValue.ToString("0.##", [System.Globalization.CultureInfo]::InvariantCulture))
    }

    & $addSection $(if ($lang -eq "en") { "Pokemon species data and moves" } else { "Données Pokémon et attaques" })
    & $addIfComboChanged "TypeMode" $(if ($lang -eq "en") { "Species types" } else { "Types des espèces" })
    & $addIfChecked "TypesMonotypeOnly" $(if ($lang -eq "en") { "Monotype types" } else { "Types monotype" })
    & $addIfComboChanged "AbilityMode" $(if ($lang -eq "en") { "Species abilities" } else { "Talents des espèces" })
    & $addIfChecked "AllowWonderGuard" "Wonder Guard" $(if ($lang -eq "en") { "allowed" } else { "autorise" })
    & $addIfComboChanged "StatMode" $(if ($lang -eq "en") { "Base stats" } else { "Stats de base" })
    & $addIfChecked "ForceOneExpYield" $(if ($lang -eq "en") { "EXP yield" } else { "EXP donnée" }) "1"
    & $addIfChecked "RandomizeMoveTypes" $(if ($lang -eq "en") { "Move types" } else { "Types d'attaques" })
    & $addIfChecked "RandomizeMovePower" $(if ($lang -eq "en") { "Move power" } else { "Puissance attaques" }) ("{0}-{1}" -f (& $textOf "MovePowerMin"), (& $textOf "MovePowerMax"))
    & $addIfChecked "RandomizeMovePP" "PP" ("{0}-{1}" -f (& $textOf "MovePPMin"), (& $textOf "MovePPMax"))
    & $addIfChecked "RandomizeMoveAccuracy" $(if ($lang -eq "en") { "Move accuracy" } else { "Precision attaques" }) ("{0}-{1}" -f (& $textOf "MoveAccuracyMin"), (& $textOf "MoveAccuracyMax"))
    & $addIfChecked "RandomizeMoveCategory" $(if ($lang -eq "en") { "Move category" } else { "Catégorie physique/spécial" })
    & $addIfChecked "RandomizePickupItems" $(if ($lang -eq "en") { "Pickup / field items" } else { "Objets ramassables" })
    & $addIfChecked "RandomizeShopItems" $(if ($lang -eq "en") { "Shop items" } else { "Objets boutiques" })
    & $addIfChecked "RandomizeTechnicalRecords" $(if ($lang -eq "en") { "TM/TR item IDs" } else { "CT/TR objets" })

    & $addSection $(if ($lang -eq "en") { "Evolutions, gifts, starters, trades" } else { "Évolutions, cadeaux, starters, trades" })
    & $addIfComboChanged "EvolutionMode" $(if ($lang -eq "en") { "Evolution targets" } else { "Cibles d'évolution" })
    & $addIfChecked "AllowLegendaryEvolutions" $(if ($lang -eq "en") { "Legendary evolutions" } else { "Légendaires en évolution" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    & $addIfChecked "NormalizeFriendshipEvolutions" $(if ($lang -eq "en") { "Friendship evolutions" } else { "Évolutions amitie" }) ("Lv. {0}" -f (& $textOf "FriendshipEvolutionLevel"))
    & $addIfChecked "NormalizeTradeEvolutions" $(if ($lang -eq "en") { "Trade evolutions" } else { "Évolutions échange" }) ("Lv. {0}" -f (& $textOf "TradeEvolutionLevel"))
    & $addIfChecked "NormalizeSpecialEvolutions" $(if ($lang -eq "en") { "Special evolutions" } else { "Évolutions spéciales" }) ("Lv. {0}" -f (& $textOf "SpecialEvolutionLevel"))
    & $addIfComboChanged "GiftMode" $(if ($lang -eq "en") { "Gift Pokemon" } else { "Pokémon cadeaux" })
    & $addIfComboChanged "StarterMode" $(if ($lang -eq "en") { "Starters" } else { "Starters" })
    $manualStarters = @(@((& $textOf "Starter1"), (& $textOf "Starter2"), (& $textOf "Starter3")) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($manualStarters.Count -gt 0) {
        & $addChange $(if ($lang -eq "en") { "Manual starters" } else { "Starters manuels" }) ($manualStarters -join " / ")
    }
    & $addIfChecked "PatchStarterRelatedTrainers" $(if ($lang -eq "en") { "Starter-related trainer patch" } else { "Patch dresseurs lies aux starters" })
    & $addIfChecked "AllowLegendaryGifts" $(if ($lang -eq "en") { "Legendary gifts/starters" } else { "Légendaires cadeaux/starters" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    & $addIfComboChanged "TradeMode" $(if ($lang -eq "en") { "NPC trades" } else { "Trades PNJ" })
    & $addIfChecked "AllowLegendaryTrades" $(if ($lang -eq "en") { "Legendary NPC trades" } else { "Légendaires trades PNJ" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })

    & $addSection $(if ($lang -eq "en") { "Encounters" } else { "Rencontres" })
    & $addIfComboChanged "StaticEncounterMode" $(if ($lang -eq "en") { "Static/scripted encounters" } else { "Rencontres fixes/scriptes" })
    if ((Normalize-Mode (& $comboValue "StaticEncounterMode")) -ne "unchanged") {
        & $addChange $(if ($lang -eq "en") { "Static mapping" } else { "Mapping statiques" }) (& $comboLabel "StaticEncounterStableMapping")
    }
    & $addIfChecked "AllowLegendaryStaticEncounters" $(if ($lang -eq "en") { "Static legendary pool" } else { "Légendaires rencontres fixes" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    & $addIfComboChanged "GrassEncounterMode" $(if ($lang -eq "en") { "Wild encounter species" } else { "Rencontres sauvages" })
    if ((Normalize-Mode (& $comboValue "GrassEncounterMode")) -ne "unchanged") {
        & $addChange $(if ($lang -eq "en") { "Wild mapping" } else { "Mapping sauvage" }) (& $comboLabel "GrassEncounterStableMapping")
    }
    & $addIfChecked "AllowLegendaryGrassEncounters" $(if ($lang -eq "en") { "Wild/visible legendary pool" } else { "Légendaires herbes/visibles" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    & $addIfComboChanged "VisibleEncounterBehavior" $(if ($lang -eq "en") { "Visible Pokemon behavior" } else { "Comportement Pokémon visibles" }) @("RomfsMatch")
    & $addIfComboChanged "EncounterDrawMode" $(if ($lang -eq "en") { "Encounter draw mode" } else { "Mode de tirage rencontres" }) @("SlotParEspece")
    & $addIfComboChanged "UndergroundMode" $(if ($lang -eq "en") { "Underground encounters" } else { "Underground" })
    & $addIfChecked "AllowLegendaryUnderground" $(if ($lang -eq "en") { "Underground legendary pool" } else { "Légendaires underground" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })

    & $addSection $(if ($lang -eq "en") { "Installation" } else { "Installation" })
    if (& $checkedOf "AutoInstallToEden") {
        $targets = New-Object System.Collections.Generic.List[string]
        foreach ($target in @(
            @{ Name = "InstallToRyujinx"; Label = "Ryujinx" }
        )) {
            if (& $checkedOf ([string]$target["Name"])) {
                [void]$targets.Add([string]$target["Label"])
            }
        }
        & $addChange $(if ($lang -eq "en") { "Auto-install targets" } else { "Cibles installation auto" }) ($targets.ToArray() -join ", ")
        & $addChange $(if ($lang -eq "en") { "Installed mod folder" } else { "Dossier de mod installe" }) (& $textOf "EdenModName")
    } else {
        & $addLine $(if ($lang -eq "en") { "- Auto-install disabled: files are generated only in the output folder." } else { "- Installation auto désactivée: les fichiers sont seulement générés dans le dossier de sortie." })
    }

    if ($Validation -and $Validation.Warnings.Count -gt 0) {
        & $addSection $(if ($lang -eq "en") { "Validation warnings" } else { "Avertissements de validation" })
        foreach ($warning in @($Validation.Warnings)) {
            & $addLine "- $warning"
        }
    }

    if ($script:GuiBuildSummaryChangedCount -lt 1) {
        & $addLine ""
        & $addLine $(if ($lang -eq "en") { "No major randomization option is enabled. The build will mostly copy required files and reports." } else { "Aucune option majeure de randomisation n'est activée. Le build va surtout copier les fichiers requis et les rapports." })
    }

    Remove-Variable -Name GuiBuildSummaryChangedCount -Scope Script -ErrorAction SilentlyContinue
    return ($lines -join [Environment]::NewLine)
}

function Show-GuiBuildSummaryDialog {
    param(
        [System.Windows.Forms.Form]$Owner,
        [string]$SummaryText,
        [string]$Language = "fr",
        [bool]$ConfirmGeneration = $true
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = if ($lang -eq "en") { "What will be modified" } else { "Ce qui va être modifie" }
    $dialog.ClientSize = New-Object System.Drawing.Size(780, 620)
    $dialog.MinimumSize = New-Object System.Drawing.Size(720, 520)
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    Initialize-PfControlLibrary
    $dialog.Font = New-GuiFont -Size 9.5

    $summaryBox = New-Object System.Windows.Forms.TextBox
    $summaryBox.Multiline = $true
    $summaryBox.ReadOnly = $true
    $summaryBox.ScrollBars = "Vertical"
    $summaryBox.WordWrap = $false
    $summaryBox.Location = New-Object System.Drawing.Point(12, 12)
    $summaryBox.Size = New-Object System.Drawing.Size(756, 548)
    $summaryBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $summaryBox.Text = $SummaryText
    $dialog.Controls.Add($summaryBox)

    $okButton = New-Object PokeFeur.Ui.PfButton
    $okButton.Size = New-Object System.Drawing.Size(170, 34)
    $okButton.Location = New-Object System.Drawing.Point(416, 574)
    $okButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $okButton.Text = if ($ConfirmGeneration) {
        if ($lang -eq "en") { "Generate" } else { "Générer" }
    } else {
        if ($lang -eq "en") { "Close" } else { "Fermer" }
    }
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dialog.AcceptButton = $okButton
    $dialog.Controls.Add($okButton)

    if ($ConfirmGeneration) {
        $cancelButton = New-Object PokeFeur.Ui.PfButton
        $cancelButton.Size = New-Object System.Drawing.Size(170, 34)
        $cancelButton.Location = New-Object System.Drawing.Point(598, 574)
        $cancelButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
        $cancelButton.Text = if ($lang -eq "en") { "Cancel" } else { "Annuler" }
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $dialog.CancelButton = $cancelButton
        $dialog.Controls.Add($cancelButton)
    }

    try {
        Apply-GuiTheme -Root $dialog -Theme $script:GuiTheme
    } catch {
    }

    return ($dialog.ShowDialog($Owner) -eq [System.Windows.Forms.DialogResult]::OK)
}

function Get-LocalizedDescriptionText {
    param([object]$Description)

    if ($Description -is [System.Collections.IDictionary]) {
        $lang = if ($script:UiLanguage -eq "en") { "en" } else { "fr" }
        if ($Description.ContainsKey($lang)) {
            return [string]$Description[$lang]
        }
        if ($Description.ContainsKey("fr")) {
            return [string]$Description["fr"]
        }
        if ($Description.ContainsKey("en")) {
            return [string]$Description["en"]
        }
        return [string]($Description.Values | Select-Object -First 1)
    }

    return [string]$Description
}

function Register-ControlDescription {
    param(
        [System.Windows.Forms.Control]$Control,
        [System.Windows.Forms.TextBox]$DetailsBox,
        [object]$Description
    )

    if (-not $Control -or -not $DetailsBox) {
        return
    }

    $getLocalizedDescriptionText = (Get-Item -LiteralPath function:\Get-LocalizedDescriptionText).ScriptBlock
    $update = {
        param($sender, $args)
        $script:LastDetailsDescription = $Description
        $DetailsBox.Text = & $getLocalizedDescriptionText -Description $Description
    }.GetNewClosure()

    $Control.Add_Enter($update)
    $Control.Add_MouseEnter($update)
}

function Add-ConcreteDescriptionExamples {
    param(
        [hashtable]$Ui,
        [string]$Language = "fr"
    )

    if (-not $Ui -or -not $Ui.Descriptions) {
        return
    }

    if ($Language -eq "en") {
        $Ui.Descriptions.TrainerSpecies = "Chooses which Pokemon the trainers send out.`r`n   Full random — their Victreebel can become Empoleon.`r`n   Balanced random — the replacement keeps a similar strength.`r`n   Keep vanilla — everyone keeps the team the game gave them.`r`n`r`nMany rules further down do NOTHING if you do not change the Pokemon."
        $Ui.Descriptions.TrainerMoves = "Chooses the four moves of the trainers' Pokemon.`r`n   4 random moves — Empoleon can pull out anything at all.`r`n   Natural moves — the ones it would know at its level.`r`n   Smogon strategic — the moves the experts recommend.`r`n`r`nIn Smogon mode, the menu next to it fills any boxes left EMPTY."
        $Ui.Descriptions.TrainerSmogonMoveFallback = "Says what to do when the experts do not give four moves.`r`n   Level moves — fill the gaps with what it learns as it grows.`r`n   Random — fill the gaps with moves picked at random.`r`n   Keep vanilla — keep the moves the trainer already had.`r`n`r`nThis menu ONLY matters if the moves are set to Smogon strategic."
        $Ui.Descriptions.TrainerItems = "Chooses the item each trainer Pokemon holds.`r`n   Only those who had one — the others stay empty-handed.`r`n   Give to everyone — even Empoleon, who had nothing, gets one.`r`n   Remove all — nobody holds anything any more.`r`n`r`nThe menu next to it decides WHICH list of items is used."
        $Ui.Descriptions.TrainerItemPool = "Decides which list the trainers' held items are drawn from.`r`n   Battle — berries, Leftovers, plates and other useful battle items.`r`n   Wide — almost the whole game, including medicine, mints and candies.`r`n`r`nTMs, Poke Balls and key items NEVER come out. Does nothing if the held items are set to keep vanilla."
        $Ui.Descriptions.TrainerAddedSlotSpecies = "Chooses the Pokemon added when a team is made bigger.`r`n   Random — anyone can turn up, even Victreebel.`r`n   Similar strength — the newcomer matches the rest of the team.`r`n   Same type — at a Grass gym leader, you get a Grass Pokemon.`r`n`r`nThis menu ONLY matters if the trainers' Pokemon are set to keep vanilla."
        $Ui.Descriptions.TrainerDuplicateMode = "Decides whether a trainer can get the same thing twice.`r`n   Block duplicates — NEVER two Empoleon on the same team.`r`n   Normal — chance does as it likes, duplicates included.`r`n`r`nBlocking also avoids handing out the same held item twice. It does nothing for a trainer with only one Pokemon."
        $Ui.Descriptions.TrainerAbility = "Chooses the ability of the trainers' Pokemon.`r`n   Random — one of the four ability slots is drawn at random.`r`n   Smogon strategic — the ability the experts recommend.`r`n   Keep vanilla — everyone keeps the ability the game gave them.`r`n`r`nIf the experts recommend nothing, a NORMAL ability of that species is picked."
        $Ui.Descriptions.TrainerIV = "Sets the trainers' IVs, the hidden talent of each Pokemon.`r`n   31 everywhere — Empoleon is perfect in all six stats.`r`n   Random — every stat rolls a number between 0 and 31.`r`n   Keep vanilla — the game's own values are left alone.`r`n`r`nThe shiny look and the right to Dynamax are NEVER touched."
        $Ui.Descriptions.TrainerEV = "Sets the EVs, the points earned from battle training.`r`n   Smogon strategic — the spread the experts recommend.`r`n   Random but valid — a legal spread drawn at random.`r`n   All zero — Victreebel has no training left at all.`r`n`r`nIf the experts have nothing for that species, a random spread TAKES OVER."
        $Ui.Descriptions.TrainerLevel = "Multiplies the level of every Pokemon the trainers own.`r`n   1.20 — a level 25 Empoleon moves up to around level 30.`r`n   0.80 — it drops back to around level 20.`r`n   1.0 — the game's levels do not move.`r`n`r`nThe result stays between 1 and 100. Wild Pokemon have their OWN setting."
        $Ui.Descriptions.TrainerTeamSize = "Sets a smallest and biggest number of Pokemon per trainer.`r`n   Minimum 3 — a trainer who only had one now gets three.`r`n   Maximum 4 — big teams come back down to four.`r`n   -1 in a box — that limit is not applied.`r`n`r`nSix is NEVER passed. A minimum of one or more gives a team even to those who had none."
        $Ui.Descriptions.TrainerTypeThemed = "Gives each trainer one single type, drawn at random, for the whole team.`r`n`r`nA trainer who lands on Water only sends out Water Pokemon. A trainer who lands on Grass can bring out Victreebel. Every trainer gets their own type.`r`n`r`nThe trainers' Pokemon must be randomized, otherwise NOTHING happens."
        $Ui.Descriptions.TrainerExtraPokemon = "Adds extra Pokemon to teams, depending on how important the trainer is.`r`n   Boss — gym leaders, Elite Four and the Champion.`r`n   Important — rivals and the leaders of the enemy team.`r`n   Normal — everybody else. Put 0 to add nothing.`r`n`r`nSix is NEVER passed, five is the most added, and a trainer with no team stays empty."
        $Ui.Descriptions.TrainerSpecialRuleScope = "Chooses who the two rules on the right apply to.`r`n   Gyms and League — only the leaders, the Elite Four and the Champion.`r`n   All bosses — rivals and enemy team leaders are added.`r`n   Everyone — every single trainer in the game.`r`n`r`nThe Diverse types menu has its OWN scope and does not follow this one."
        $Ui.Descriptions.TrainerLegendaryPolicy = "Decides how many legendaries the trainers picked on the left receive.`r`n   None — they vanish from those teams completely.`r`n   One each — exactly one per team, the rest stays normal.`r`n   All legendaries — the whole team, and it is brutally hard.`r`n`r`nAsking for them hands them out EVEN IF the Allow legendaries box is unticked."
        $Ui.Descriptions.TrainerMinBaseStatTotal = "Forces the trainers picked on the left to use only strong enough Pokemon.`r`n`r`nThe total adds up the six base stats of a Pokemon. Rattata is 253, Charizard is 534, Mewtwo is 680. Type 600 and you only face MONSTERS; 0 to switch it off.`r`n`r`nIf fewer than three species clear the bar, the twelve strongest are kept."
        $Ui.Descriptions.AllowLegendaryTrainers = "Tick this so trainers can receive legendary and mythical Pokemon.`r`n`r`nMewtwo, Zacian or Mew can then stand in front of you. Unticked, they stay out of the teams the tool builds. A legendary the game already gave a trainer stays put.`r`n`r`nThe All legendaries rule OVERRIDES this box and hands them out anyway."
        $Ui.Descriptions.AllowLegendaryGrass = "Allows legendaries in the tall grass and among the Pokemon roaming outside.`r`n`r`nA lakeside Victreebel can become a Kyogre. A Zacian can wander a route, visible from far away. Unticked, you NEVER meet a wild legendary.`r`n`r`nDoes nothing if you do not change the wild grass Pokemon."
        $Ui.Descriptions.AllowLegendaryStatic = "Allows legendaries for the Pokemon the story places at a fixed spot.`r`n`r`nThe one waiting at the end of a cave can become a Lugia. An Empoleon standing near a bridge can become a Rayquaza. Those Pokemon show on screen BEFORE you touch them.`r`n`r`nDoes nothing if you do not change the fixed encounters."
        $Ui.Descriptions.AllowLegendaryGifts = "Allows legendaries among the Pokemon you are given, starters included.`r`n`r`nThe Pokemon handed to you by a character can become a Mew. Your first starter can become a Zacian if you randomize it. Gifts and starters draw from the SAME list.`r`n`r`nDoes nothing if you change neither the gifts nor the starters."
        $Ui.Descriptions.AllowLegendaryTrades = "Allows legendaries in the trades offered by the game's characters.`r`n`r`nThe Pokemon they ask you for can become a Kyogre. The Pokemon they hand back can become a Lugia. BOTH sides of the trade are affected.`r`n`r`nDoes nothing if you do not change the trades."
        $Ui.Descriptions.AllowLegendaryUnderground = "Allows legendaries in Dynamax Adventures, the team cave run of the Crown Tundra.`r`n`r`nA Victreebel met in a room can become a Necrozma. Every room of the run can therefore hide a legendary. The Wild Area raid dens are NOT affected.`r`n`r`nDoes nothing if you do not change the Dynamax Adventure Pokemon."
        $Ui.Descriptions.AllowLegendaryEvo = "Allows legendaries as the result of a randomized evolution.`r`n`r`nYour Victreebel can evolve into a Zacian. A tiny early Pokemon can lead straight to a Mewtwo. Unticked, NO evolution ever leads to a legendary.`r`n`r`nBest left off if you want a fair early game."
        $Ui.Descriptions.AllowWonderGuard = "Lets Wonder Guard show up when the tool shuffles abilities.`r`n`r`nIt is Shedinja's ability: ONLY super effective moves can hurt it. An Empoleon with Wonder Guard can become impossible to beat. Left unticked, only Shedinja keeps it.`r`n`r`nTick it only if you enjoy nasty surprises."
        $Ui.Descriptions.MaxTrainerAI = "Gives every trainer the best battle brain in the game.`r`n`r`nThey switch Pokemon at the right moment. They look for the move that hurts you the most. They use their healing items when they should.`r`n`r`nFights get clearly harder WITHOUT changing a single Pokemon."
        $Ui.Descriptions.ForceTrainerFullyEvolved = "Fully evolves trainers' Pokemon from the level you set on the right.`r`n`r`nAt level 45 a trainer's Weepinbell becomes a Victreebel. BELOW that level nothing changes. When several final evolutions exist, one is drawn at random.`r`n`r`nHandy so late-game trainers stop sending out babies."
        $Ui.Descriptions.ForceTrainerCanDynamax = "Lets EVERY trainer Dynamax, not only the ones the game allowed.`r`n`r`nAny random trainer can now make their Empoleon giant. The giant Pokemon lasts three turns, as usual. Gigantamax forms are not added, though.`r`n`r`nCareful: ordinary battles become clearly harder."
        $Ui.Descriptions.TrainerDynamaxLevel = "Sets the Dynamax level of trainer Pokemon, so their HP once they go giant.`r`n   Keep vanilla — everyone keeps the level the game gave them.`r`n   Level 10 — HP is doubled when the Pokemon goes giant.`r`n   Random 0 to 10 — each Pokemon gets a level drawn at random.`r`n`r`nEven at level 0 the HP still goes up by HALF."
        $Ui.Descriptions.TrainerShinyChance = "Chance, in percent, that each trainer Pokemon is shiny.`r`n   0 — none at all, just like the normal game.`r`n   5 — about one trainer Empoleon in twenty sparkles.`r`n   100 — every single Pokemon of every single trainer sparkles.`r`n`r`nIt looks nice, but it changes NOTHING about the Pokemon's strength."
        $Ui.Descriptions.ForceBossTargets = "List of the trainers counted as bosses. It is there to be READ, not filled in.`r`n`r`nIt changes as soon as you switch the boss choice above. It gives you the exact names before you start generating. Hop's very first battle, at the starter choice, is never in it.`r`n`r`nIf the boss teams box is unticked, the list says so instead."
        $Ui.Descriptions.ValidateBuild = "Checks your settings and your game files before you launch a build.`r`n`r`nIt lists whatever would block, such as a missing ROMFS folder or an option that needs the ExeFS without one being provided."
        $Ui.Descriptions.BuildSummary = "Shows in plain words everything you changed compared to the original game.`r`n`r`nWorth reading before you generate: it is the FASTEST way to spot an option you turned on by mistake."
        $Ui.Descriptions.UiLanguage = "Language of this window: French or English.`r`n`r`nThe change is IMMEDIATE and none of your settings are lost."
        $Ui.Descriptions.ReportLanguage = "Language of the report files written next to the generated run.`r`n`r`nIt is INDEPENDENT from this window's language: you can read the interface in French and produce English reports."
        $Ui.Descriptions.InstallTargetRyujinx = "Copies the generated run into the mod folder of Ryujinx.`r`n`r`nCLOSE the emulator before generating: an open file makes the copy fail."
        $Ui.Descriptions.StarterMinBaseStatTotal = "The lowest strength a starter you are offered can have.`r`n`r`nThe total adds up the six base stats: a normal starter sits around 310. Put 500 here to begin with something already strong. Put 0 to set no minimum.`r`n`r`nDoes nothing if you typed the starters BY HAND."
        $Ui.Descriptions.StarterMaxBaseStatTotal = "The highest strength a starter you are offered can have.`r`n`r`nThe total adds up the six base stats: a normal starter sits around 310. Put 350 here so you do not begin with something far too strong. Put 0 to set no maximum.`r`n`r`nDoes nothing if you typed the starters BY HAND."
        $Ui.Descriptions.EvolutionLimitToThreeStages = "Cuts every evolution chain down to THREE Pokemon at most.`r`n`r`nOnce evolutions are randomized, a chain can run eight deep, or loop forever. With this on, the third Pokemon of a chain stops evolving entirely.`r`n`r`nWithout randomized evolutions there is nothing to cut: the game never goes past three."
        $Ui.Descriptions.FollowEvolutionsForTypes = "Gives a whole family the same types as its first Pokemon.`r`n`r`nIf Weepinbell turns Fire, the Victreebel it evolves into turns Fire too. Without this, evolving can flip the family types completely. The families followed are the ORIGINAL ones.`r`n`r`nType randomization must be on, otherwise this does nothing."
        $Ui.Descriptions.FollowEvolutionsForAbilities = "Gives a whole family the same abilities as its first Pokemon.`r`n`r`nAll three abilities are copied over, hidden ability included. Evolving NEVER takes an ability away by surprise. The families followed are the ORIGINAL ones.`r`n`r`nAbility randomization must be on, otherwise this does nothing."
        $Ui.Descriptions.TrainerForceDiverseTypes = "Stops a trainer from having two Pokemon that share a type.`r`n`r`nOne super effective move can no longer sweep the whole team. Pick who it affects: gyms and League, all bosses, or everyone. Trainers who already have a type theme are left alone.`r`n`r`nOnce no free type is left, the rule STOPS instead of blocking."
        $Ui.Descriptions.WildLevelPercent = "Changes the level of every wild Pokemon by a percentage.`r`n`r`n0 changes NOTHING at all. 50 turns a level 20 Empoleon into a level 30 one. -50 drops it to level 10, for an easier run.`r`n`r`nLevels stay between 1 and 100, and the lowest always stays under the highest."
        $Ui.Descriptions.EvolutionForceGrowth = "The evolution must be STRONGER than the current form.`r`n`r`nSame as setting the minimum gain to 1. It stops a Pokemon from getting weaker when it evolves. To pick the threshold yourself, use the minimum gain.`r`n`r`nIf both are set, the minimum gain wins."
        $Ui.Descriptions.EvolutionSameType = "The evolution keeps a SHARED type.`r`n`r`nPikachu (Electric) can become Raikou (Electric). Pikachu will not become Magikarp (Water). This stacks with the minimum stat gain.`r`n`r`nIf no Pokemon fits, the type is kept first and the stat threshold is relaxed instead."
        $Ui.Descriptions.MinimumCatchRate = "Makes every Pokemon at least as easy to catch as the number you type.`r`n`r`nThe number goes from 0 to 255: the bigger it is, the easier the catch. Put 255 and almost any Ball catches almost anything first throw. Put 0 to change nothing.`r`n`r`nA Pokemon already easier keeps its value, so this can NEVER make catching harder."
        $Ui.Descriptions.ExpCurveMode = "Chooses how fast every Pokemon levels up.`r`n   All fast — everyone levels quickly.`r`n   All slow — the game becomes a long grind.`r`n   All medium — ONE single speed for everyone.`r`n`r`nDo not change leaves each Pokemon the speed it has in the original game."
        $Ui.Descriptions.TutorCompatibilityMode = "Chooses which Pokemon the 18 move tutors agree to train.`r`n   One in two — a coin flip for each tutor on each Pokemon.`r`n   Learn everything — all 18 tutors train every Pokemon.`r`n`r`nLike TMs and TRs, this ONLY changes who may learn, never what is taught."
        $Ui.Descriptions.TmCompatibilityMode = "Chooses which Pokemon may learn each of the 200 TMs and TRs.`r`n   One in two — a coin flip for every machine on every Pokemon.`r`n   Prefer same type — a machine matching the Pokemon passes 9 times out of 10.`r`n   Learn everything — everyone learns everything. Very strong.`r`n`r`nThis NEVER changes what a machine teaches, only who may learn it."
        $Ui.Descriptions.RandomizeWildHeldItems = "Changes the items wild Pokemon are holding.`r`n`r`nYou can steal them with Thief, or keep them by catching the Pokemon. ONLY Pokemon that already held something get a new item, so every catch does not turn into a free prize.`r`n`r`nImportant story items are never handed out: they could block your adventure."
        $Ui.Descriptions.ModOverworldShiny = "Shows shiny Pokemon before the battle, while they walk around outside.`r`n`r`nA shiny Empoleon really wears its rare colours. A sound plays and sparkles appear around it. It works on Pokemon that bite while fishing too.`r`n`r`nThe ODDS do not change, unless you fill the box next to this one."
        $Ui.Descriptions.OverworldShinyBoostPercent = "Forces a share of the Pokemon appearing outside to be shiny.`r`n`r`n0 keeps the game's normal odds, which are very low. 5 makes about one Empoleon out of twenty shiny. 100 makes every single one shiny.`r`n`r`nIt only works if the overworld shiny box is TICKED."
        $Ui.Descriptions.ModUncapLevel = "Removes the level limit your badges put on wild Pokemon.`r`n`r`nA high level Empoleon can show up right at the start. You can catch it, when the game used to REFUSE. It can be shiny, which was impossible before too.`r`n`r`nThis matters most in the Wild Area, where the game blocked you hardest."
        $Ui.Descriptions.ModUnderworld = "Brings tall-grass Pokemon out into the open.`r`n`r`nSome Pokemon only live in the grass and are never visible. This option makes them show up on screen: Snorlax and Gengar never roam around normally.`r`n`r`nYou can then SEE them and choose to fight them, instead of meeting them at random."
        $Ui.Descriptions.ModExtendedFollowing = "Keeps your following Pokemon visible when you enter the Wild Area.`r`n`r`nThe game normally hides it the moment you step in."
        $Ui.Descriptions.ModGlimwoodOverworld = "Makes Pokemon appear on screen in Glimwood Tangle, the glowing mushroom forest.`r`n`r`nNormally none ever show there: it all happens in the grass. Here you see Victreebel wandering between the trees. The number next to it says how many can show at once.`r`n`r`nONLY that forest is affected, the rest of the game stays the same."
        $Ui.Descriptions.GlimwoodMaxSpawns = "How many Pokemon may roam Glimwood Tangle at the same time.`r`n`r`nThe higher the number, the busier the forest, and the harder your emulator works."
        $Ui.Descriptions.LearnsetMoveMode = "Changes which moves each Pokemon learns as it levels up. The levels NEVER move.`r`n   Shuffle — the same moves, spread differently. None is lost.`r`n   Random — from the 610 moves some species already learns by level up.`r`n   Full random — from all 787 moves, even those never learned that way.`r`n`r`nEmpoleon keeps the same number of moves at the same levels, just not the same ones."
        $Ui.Descriptions.TmMoveMode = "Changes which move each of the 200 TMs and TRs teaches.`r`n   Shuffle — the same 200 moves, just not on the same machines.`r`n   Random — a move can appear twice while another vanishes.`r`n`r`nThe items and their prices NEVER move: a TM stays a TM. This does not say who can learn it: that is the compatibility setting."
        $Ui.Descriptions.ModDexAnimations = "Spawns a Ditto next to you when the field loads.`r`n`r`nTalk to it to pick an animation from a list. Pokemon then play that animation instead of their own. It is a toy for taking pictures and videos.`r`n`r`nIt only shows up ONCE per session, so restart the game if you missed it."
        $Ui.Descriptions.ModFishingTweaks = "Keeps your fishing streak going even when a brilliant Pokemon bites.`r`n`r`nNormally that brilliant Pokemon resets your streak to zero. Here you keep fishing in the same spot and lose nothing. Very long streaks become far less painful.`r`n`r`nIt changes NEITHER the Pokemon you fish up nor their levels."
        $Ui.Descriptions.ModSynchroMode = "Lets you walk the Pokemon that follows you around yourself.`r`n`r`nPress L and R together to swap between the two. Your character hides and the Pokemon moves instead. Press L and R again to take your character back.`r`n`r`nYou NEED a Pokemon following you, otherwise nothing happens."
        $Ui.Descriptions.ModCameraTweaks = "Frees the camera: it turns faster, tilts further and pulls back further.`r`n`r`nYou can pull the view back to see a whole clearing at once. You can tilt it further to look at what lies ahead. Your character moves exactly as before.`r`n`r`nThe settings are FIXED, there is no number for you to type in."
        $Ui.Descriptions.ModFreecam = "Detaches the camera from your character so it flies and shows you the map.`r`n`r`nR and A together detach it, then reattach it when you are done. The D-pad moves it, ZL and ZR bring it down or up. L and R make it move slower or faster.`r`n`r`nYour character stays put and does NOT move while you do this."
        $Ui.Descriptions.RandomizeFieldItems = "Changes the items lying on the ground, the ones you pick up by walking onto them.`r`n`r`nA Potion on the ground can become a Fire Stone. A Poke Ball on the ground can become a TM. There are 247 of them in the game.`r`n`r`nThe ball you see always looks the same. ONLY what is inside changes."
        $Ui.Descriptions.RandomizeHiddenItems = "Changes the invisible items hidden in the ground.`r`n`r`nYou walk over the right spot and you find something. You NEVER see them before picking them up. There are over 4000 of them.`r`n`r`nSame idea as the items lying on the ground, but these ones are invisible."
        $Ui.Descriptions.FieldItemPoolMode = "Picks what you can find on the ground.`r`n   Without key items — never a quest item. You can never get stuck.`r`n   Everything — adds TMs and TRs. You can find moves anywhere.`r`n`r`nEither way, an item the game does not know is NEVER written."
        $Ui.Descriptions.ShopPriceMultiplier = "Changes how much items cost in shops.`r`n   x2 — a Poke Ball at 200 costs 400.`r`n   Free — everything costs 0, money stops mattering.`r`n   Random — each price is drawn between the two bounds shown.`r`n`r`nAn item the game never sells stays unsellable. This changes PRICES only, not stock."
        $Ui.Descriptions.RandomizeNatures = "Picks the nature of the trainers' Pokemon.`r`n   Keep vanilla — nothing moves.`r`n   Random — one of the 25 natures, drawn at random.`r`n   Strategic — the one that fits the build chosen for that Pokemon.`r`n`r`nIn strategic mode the moves, item, ability and EVs come from that SAME build."
        $Ui.Descriptions.ForceAllTeams = "Gives 6 Pokemon to EVERY trainer in the game.`r`n`r`nA trainer who only had 2 gets 4 more. The new ones arrive around the average level of the original team. They then go through your other settings, like the rest.`r`n`r`nA trainer with no Pokemon gets none: we do not invent battles."
        $Ui.Descriptions.ForceBossTeams = "Brings the teams of the bosses chosen next to it up to SIX Pokemon.`r`n`r`nA leader who only had three now fields six. The added Pokemon follow the same rules as all the others. Ordinary trainers are left alone.`r`n`r`nPointless if you already set every team in the game to six."
        $Ui.Descriptions.BossTeamsScope = "Chooses which trainers count as bosses for the option just above.`r`n   Major bosses — the gyms, plus rivals and the big story battles.`r`n   Gyms and league only — leaders, league battles and Leon.`r`n`r`nThe list on the right updates at once, so you SEE who is included."
        $Ui.Descriptions.TypeMode = "Takes each Pokemon's types away and gives it new ones at random.`r`n`r`nEmpoleon can become Grass and Poison, Victreebel can become Fire. About four times out of ten it ends up with a single type. Weaknesses follow the new types.`r`n`r`nThe box next to it gives everyone a single type, with NO exception."
        $Ui.Descriptions.TypesMonotypeOnly = "Gives every Pokemon a SINGLE type instead of two.`r`n`r`nEmpoleon becomes plain Fire, never Fire and Steel. No Pokemon in the game has a dual type any more. Weaknesses become far easier to remember.`r`n`r`nDoes nothing if the menu next to it keeps the types unchanged."
        $Ui.Descriptions.AbilityMode = "Changes Pokemon abilities, those powers that act on their own in battle.`r`n`r`nThe three possible abilities of a species are all redrawn at random. Victreebel can inherit the ability of a completely different Pokemon. EVERY Victreebel gets those same new abilities.`r`n`r`nWonder Guard is left out by default: the box next to it lets it back in."
        $Ui.Descriptions.StatMode = "Changes the six base stats of every Pokemon.`r`n   Shuffle — Empoleon's six numbers are put back in a different order.`r`n   Redistribute — the total stays the same, spread out anew.`r`n   Keep vanilla — the stats stay the ones from the game.`r`n`r`nEither way the TOTAL does not move: a strong Pokemon stays strong, differently."
        $Ui.Descriptions.ExpYieldMultiplier = "Multiplies all the experience you earn in battle.`r`n   2.5 — a battle that gave 400 points now gives about 1000.`r`n   0.5 — you level up twice as slowly.`r`n   1.0 — you keep the game's normal experience.`r`n`r`nThis needs the mod installed. The One point box next to it WINS over it."
        $Ui.Descriptions.ForceOneExpYield = "Makes a defeated Pokemon give only ONE experience point.`r`n`r`nA Victreebel that gave 350 points now gives one. Your Pokemon barely level up any more. No mod needed: it is written straight into the game.`r`n`r`nWhen ticked, this box cancels the experience multiplier next to it."
        $Ui.Descriptions.MoveTypeMode = "Rolls a random type for every move in the game.`r`n`r`nThunderbolt can become a Fire-type move. Weaknesses and the same-type bonus follow the new type. Even status moves change type.`r`n`r`nEmpoleon can end up with NOT A SINGLE move matching its own types."
        $Ui.Descriptions.MovePowerMode = "Rolls a random power for every move that deals damage.`r`n`r`nTackle can jump from 40 to 130 power. Hydro Pump can drop to 25 and barely hurt any more. The two boxes next to it set the minimum and maximum.`r`n`r`nStatus moves, which deal no damage, are NEVER touched."
        $Ui.Descriptions.MovePPMode = "Rolls random PP for every move, meaning how often you can use it.`r`n`r`nA move with 15 PP can drop to 5 or climb to 40. EVERY move is affected, status moves included. The two boxes next to it set the minimum and maximum.`r`n`r`nWith a very low minimum, you will spend a lot of time at the Pokemon Center."
        $Ui.Descriptions.MoveAccuracyMode = "Rolls a random accuracy for every move, its chance to hit.`r`n`r`nHydro Pump can become reliable and never miss again. Tackle can start missing one time out of three. The two boxes next to it set the minimum and maximum.`r`n`r`nStatus moves are affected TOO, Thunder Wave for instance."
        $Ui.Descriptions.MoveCategoryMode = "Decides whether a move hits with Attack or with Special Attack.`r`n`r`nFlamethrower can become a physical move. Iron Head can become a special move. ONLY moves that deal damage are affected.`r`n`r`nA Pokemon built for close combat can inherit moves that no longer suit it."
        $Ui.Descriptions.StarterMode = "Changes the three starters the game offers you at the beginning.`r`n   Random — Grookey can become Empoleon.`r`n   Similar strength — all three stay close to the original.`r`n   Keep vanilla — you keep Grookey, Scorbunny and Sobble.`r`n`r`nIf you fill the three boxes by hand, ALL THREE are needed, and three different species."
        $Ui.Descriptions.Starter1 = "First forced starter.`r`n`r`nFill in ALL THREE boxes to pick your exact trio, or leave them empty to let the mode above decide. French and English names are both accepted."
        $Ui.Descriptions.Starter2 = "Second forced starter.`r`n`r`nThe three boxes work together: three filled force the trio, three empty hand control back to the mode above."
        $Ui.Descriptions.Starter3 = "Third forced starter.`r`n`r`nType the name as it appears in game, in French or in English."
        $Ui.Descriptions.PatchStarters = "Updates the trainers who owned an original starter, after your new trio.`r`n   Hop had Grookey — he gets your first new starter instead.`r`n   Evolved forms follow — Rillaboom becomes that same base Pokemon.`r`n`r`nTheir four moves are rebuilt to match. Best left ticked: otherwise those trainers keep a starter you NO LONGER have."
        $Ui.Descriptions.EvolutionMode = "Changes what each Pokemon evolves into.`r`n   Random — Ponyta can evolve into Empoleon.`r`n   Similar strength — the evolution stays within 55 points.`r`n   Keep vanilla — evolutions stay the ones from the game.`r`n`r`nLevels and conditions are NOT changed here: the settings below handle that."
        $Ui.Descriptions.NormalizeFriendship = "Turns friendship evolutions into a plain level-up at the level you pick.`r`n`r`nEevee no longer has to love you: it evolves at the level in the box. Riolu becomes Lucario just by levelling up. The day and night versions are handled the SAME way.`r`n`r`nHandy: friendship takes a very long time to raise in a quick run."
        $Ui.Descriptions.NormalizeTrade = "Turns trade evolutions into a plain level-up at the level you pick.`r`n`r`nMachoke becomes Machamp on its own, with no friend to trade with. Haunter becomes Gengar just by levelling up. Trades that need a held item work the same way.`r`n`r`nA MUST if you play alone: otherwise those evolutions are impossible."
        $Ui.Descriptions.NormalizeSpecial = "Turns every other evolution condition into a plain level to reach.`r`n`r`nNO MORE special place, time of day, weather or stone needed. No more known move and no more held item needed. With the two boxes above unticked, friendship and trade land here too.`r`n`r`nEvolutions that already worked by level keep the game's own level."
        $Ui.Descriptions.NpcGiftItemMode = "Changes the items characters hand you.`r`n   Shuffle — the gifts swap between characters.`r`n   Random — each gift becomes any item.`r`n`r`nKey items are NEVER touched: Rotom Bike, Dynamax Band, Endorsement. Replacing one would make your game unfinishable."
        $Ui.Descriptions.GiftMode = "Changes the Pokemon characters give you during the adventure.`r`n   Random — the gift Toxel can become Victreebel.`r`n   Similar strength — the gift stays close.`r`n   Keep vanilla — you receive the gifts the game planned.`r`n`r`nThe three starters are NOT affected: they have their own menu next to it."
        $Ui.Descriptions.TradeMode = "Changes the Pokemon in trades with the game's characters.`r`n   Random — they ask for Empoleon and hand you Victreebel.`r`n   Similar strength — both stay close.`r`n   Keep vanilla — the trades do not move.`r`n`r`nBOTH sides change. Careful: you really have to own the Pokemon they ask for."
        $Ui.Descriptions.StaticMode = "Changes the fixed encounters, the ones the story puts in front of you.`r`n   Random — the story legendary can become Victreebel.`r`n   Similar strength — the replacement stays close.`r`n   Keep vanilla — those encounters do not move.`r`n`r`nThe menu below decides whether two identical encounters give the SAME replacement."
        $Ui.Descriptions.StaticStableMapping = "Decides whether two identical fixed encounters give the same replacement.`r`n   By species — every fixed Empoleon becomes the SAME Pokemon.`r`n   By spot — each encounter is drawn on its own, remembering nothing.`r`n`r`nUseless if fixed encounters do not change. In by-species mode the grass follows."
        $Ui.Descriptions.GrassMode = "Changes the wild Pokemon you meet in the tall grass.`r`n   Random — a Skwovet can become Empoleon.`r`n   Similar strength — the replacement stays within 55 points.`r`n   Keep vanilla — the grass does not move.`r`n`r`nThe two menus below decide what you SEE outside and what you FIGHT."
        $Ui.Descriptions.GrassStableMapping = "Decides how the wild encounter tables are rewritten.`r`n   By slot — each slot is drawn on its OWN: one Victreebel of a zone can become Empoleon while the Victreebel of the next slot becomes something else.`r`n   By species — within a zone and a table, every Victreebel becomes the SAME replacement.`r`n`r`nBy species keeps a run readable, by slot is the chaotic one. Does nothing if the wild grass Pokemon are set to Keep vanilla."
        $Ui.Descriptions.VisibleEncounterBehavior = "Superseded setting: the two lists below are the ones that decide.`r`n`r`nOne for what you see, one for what you fight. This choice now only has a MARGINAL effect on which files are copied. It is hidden so it does not pretend to steer anything.`r`n`r`nUse the visible and battle Pokemon lists instead."
        $Ui.Descriptions.EncounterDrawMode = "Picks how the replacement is drawn.`r`n   Slot per species — an Empoleon always gives the same replacement in a zone.`r`n   Full random — a new replacement on every encounter.`r`n`r`nWith slot per species you can LEARN a zone. With full random you can predict nothing."
        $Ui.Descriptions.LiveVisibleMode = "Changes the Pokemon you SEE roaming outside.`r`n   Unchanged — the game's own ones.`r`n   Random — a new one on every spawn.`r`n   Per zone — each zone keeps its own.`r`n   Discovery — the grass stays vanilla until a battle reveals it.`r`n   Discovery, random grass — same, but a random decoy stands in instead of the vanilla one.`r`n`r`nIn both Discovery modes: you fight a Victreebel, and Victreebel then roams there for good. Only what you see BEFORE that first battle differs."
        $Ui.Descriptions.LiveBattleMode = "Changes the Pokemon you FIGHT.`r`n`r`nSet it differently from the visible one and you get the hidden battle: you see an Empoleon and you fight a Victreebel. Seeing a Pokemon outside no longer tells you what you will get.`r`n`r`nThis is the Nuzlocke setting: you cannot pick your catch by sight."
        $Ui.Descriptions.AllowLegendaryLiveVisible = "Allows legendaries among the Pokemon you SEE roaming outside.`r`n`r`nA Zacian can show up in place of an Empoleon. Only the ones the game can display outside may appear. The one you fight depends on the box next to this one.`r`n`r`nDoes nothing if you do not change the Pokemon visible outside."
        $Ui.Descriptions.AllowLegendaryLiveBattle = "Allows legendaries among the Pokemon you actually FIGHT.`r`n`r`nYou see an Empoleon in the grass and you fight a Mewtwo. Every legendary is possible, even those never shown outside. What you see depends on the box next to this one.`r`n`r`nDoes nothing if you do not change the Pokemon you fight."
        $Ui.Descriptions.OverworldVisibleMaxHitbox = "Keeps bulky Pokemon from standing in your way outside.`r`n`r`nIt uses the game's OWN collision radius, not the Pokedex height: Rayquaza is coiled up and only scores 70, while Gyarados scores 220. Median across 664 species is 47, the biggest are Wailord and Onix at 400.`r`n   No colossal ones — drops 4 species.`r`n   No very large ones — drops 7.`r`n   No large ones — drops 31, Gyarados included.`r`n   Compact only — drops 85.`r`n`r`nIt touches ONLY what you see. You can still battle them, and a colossus you already revealed in Discovery mode will keep roaming its zone."
        $Ui.Descriptions.OverworldVisiblePoolMode = "Decides WHICH species may show up outside.`r`n   Every species — all 664 playable ones. This is the default.`r`n   Meant to be seen outside — back to the 330 the game itself uses.`r`n   TEST: only the unintended ones — keeps ONLY the species the game never shows outside.`r`n`r`nChecked in game on 2026-09-09: Persian and Goodra, which Sword/Shield NEVER show outside, appear correctly and can be battled. The 330 cap was a content choice, not an engine limit."
        $Ui.Descriptions.LiveGenerationFilter = "Limits Pokemon to certain generations.`r`n   1,2,8 — write the numbers separated by commas.`r`n   Empty — no limit at all.`r`n   1 — only first-generation Pokemon.`r`n`r`nThis filter applies to EVERYTHING by default. The boxes below can give a different one to what you fight, what you are given, and to opposing teams."
        $Ui.Descriptions.GenerationFilterVisible = "WARNING: this setting has NEVER been seen working, on Sword or Shield.`r`n`r`nIt limits the generations of what you SEE outside. Empty: follows the general filter. In Discovery mode it can do nothing: the grass stays vanilla.`r`n`r`nUse the general filter if you want a sure result."
        $Ui.Descriptions.GenerationFilterBattle = "Limits the generations of what you FIGHT.`r`n`r`nEmpty: follows the general filter. It applies to tall grass, static encounters and the underground. You can see generation 1 and fight generation 2.`r`n`r`nThis setting decides what you can actually CATCH."
        $Ui.Descriptions.GenerationFilterGifts = "Limits the generations of what you are GIVEN.`r`n`r`nEmpty: follows the general filter. It applies to gifts, starters and in-game trades. Put 1 and you will only be given first-generation Pokemon.`r`n`r`nLeave the trainer filter empty for player on generation 1, opponents on everything."
        $Ui.Descriptions.GenerationFilterTrainers = "Limits the generations of opposing TEAMS.`r`n`r`nEmpty: follows the general filter. Leave it empty and trainers can use anything. Put 1 and trainers will only use first-generation Pokemon.`r`n`r`nIndependent from what you can catch yourself."
        $Ui.Descriptions.EvolutionMinBstGain = "Requires the evolution to be at least as strong.`r`n   -1 — no rule, the evolution can be weaker.`r`n   0 — at least equal.`r`n   10 — at least 10 more base stat points.`r`n`r`nThis is a FLOOR, not a target: a far stronger Pokemon is still allowed."
        $Ui.Descriptions.OverworldModelSafeEncounters = "REMOVED setting: it promised something the measurements did not support.`r`n`r`nIt claimed to keep outside only the species the game can display there. Counting the model files showed that promise was wrong, so the box was taken out.`r`n`r`nSafety comes from elsewhere: the species you see stays the game's own."
        $Ui.Descriptions.WriteInstallationPackage = "Creates the Installation folder, ready to copy.`r`n   Checked — one folder per emulator, ready to paste.`r`n   Unchecked — faster generation.`r`n`r`nYour ROM is COMPLETE in the output folder either way. The Installation folder is a convenience copy: 6210 files duplicated for seven emulators."
        $Ui.Descriptions.StrictDataFiles = "Stops everything if a data file is missing.`r`n   Checked — generation FAILS instead of carrying on.`r`n   Unchecked — it carries on and reports what is missing.`r`n`r`nUseful to check an installation. Without those files, reports show numbers instead of names."
        $Ui.Descriptions.RandomizeTrainerNatures = "Gives trainer Pokemon a random nature.`r`n`r`nA nature raises one stat and lowers another. An Adamant Empoleon hits harder but moves slower. This affects OPPONENTS only, never your own team.`r`n`r`nSmall on its own, noticeable across a whole battle."
        $Ui.Descriptions.TrainerBagItemMode = "Changes what trainers carry in their bag.`r`n   Empty bag — no trainer heals their Pokemon any more.`r`n   Random — other items, of the same kind.`r`n`r`n52 trainers out of 437 carry one. Without this, a gym leader can undo a whole battle with ONE Full Heal."
        $Ui.Descriptions.ShopItemMode = "Picks what can replace an item in a shop.`r`n   Same kind — a ball becomes a ball, a potion a potion.`r`n   Whatever the shop sells — it mixes its own aisles.`r`n`r`nNEITHER mode puts up an item from an aisle the shop does not know: that is what emptied the list and crashed the game."
        $Ui.Descriptions.UndergroundMode = "Changes the Pokemon of the underground areas, which have their own list.`r`n   Random — any species can come out of the ground.`r`n   Similar strength — the replacement stays close.`r`n   Keep vanilla — nothing changes underground.`r`n`r`nIt is a SEPARATE list: changing the tall grass does not touch it."
        $Ui.Descriptions.DisableExpShare = "Turns EXP Share off at the start: ONLY the Pokemon that fight earn experience.`r`n`r`nYour team levels more slowly, and you have to rotate your Pokemon. With the PC menu on, you can switch it back on from a Pokemon Center.`r`n`r`nThis only works if the mod is properly installed with the game."
        $Ui.Descriptions.EarlyBike = "REQUIRES EXEFS. Gives you the Rotom Bike right from the start.`r`n`r`nThe module hands it over ONCE, the first time the field loads on a save."
        $Ui.Descriptions.RuntimePcControls = "Adds a menu when you use the PC in a Pokemon Center.`r`n`r`nIt shows whether shared EXP and the EXP boost are on. You can change them mid-game, without rebuilding a ROM. The Boxes, the Poke Job desk and the Card Studio still work.`r`n`r`nIt picks NO setting on its own: it only opens the menu."
        $Ui.Descriptions.DynamicExpLevelCap = "REQUIRES EXEFS. Blocks experience above a level cap that rises with your progress.`r`n`r`nA Pokemon that has reached the cap only gains one experience point; those below it level up normally."
        $Ui.Descriptions.StrictBossMaxLevelCap = "REQUIRES EXEFS. Sets the cap on the strongest Pokemon of the next boss.`r`n`r`nIf that boss fields a level 28 Pokemon, you cannot pass 28 until you beat it."
        $Ui.Descriptions.MainStorySoftLevelCap = "REQUIRES EXEFS. A level cap that follows the main story.`r`n`r`nMeasured on Sword: inside each badge block the gym leader is always the strongest battle, so this cap lands on exactly the same values as the gym cap."
        $Ui.Descriptions.GymLeagueStoryLevelCap = "REQUIRES EXEFS. Caps your level on the gyms and the champion.`r`n`r`nThe caps are read from the teams ACTUALLY generated, not from the original ones."
        $Ui.Descriptions.StoryMajorBattleOrderLevelCap = "REQUIRES EXEFS. A level cap that follows the order of the major battles.`r`n`r`nMilo, Nessa, Kabu, the champions, Piers and Leon are placed back in story order, and the caps follow that sequence."
        $Ui.Descriptions.AutoInstallToEden = "Copies the finished mod straight into your emulators, with no file for you to move.`r`n`r`nOnly emulators that are both TICKED and found on your disk get a copy. Close them before generating: an open file makes the copy fail."
        $Ui.Descriptions.EdenModName = "Name of the folder created inside your emulators.`r`n`r`nKeep the SAME name and each build replaces the previous one. Change it, say to MyRun2, and both mods live side by side."
        foreach ($key in @($Ui.Descriptions.Keys)) {
            if ([string]$Ui.Descriptions[$key] -notmatch "Example:") {
                $Ui.Descriptions[$key] = ([string]$Ui.Descriptions[$key]).TrimEnd() + " Example: if the option affects a species, think Victreebel becoming Empoleon; if it affects a rule, Victreebel and Empoleon are the reference pair used to understand the result."
            }
        }
        return
    }

    $Ui.Descriptions.TrainerSpecies = "Choisit quels Pokémon les dresseurs envoient au combat.`r`n`r`n   Aléatoire complet — leur Empiflor peut devenir Pingoléon.`r`n   Force proche — le remplaçant garde une force comparable.`r`n   Ne pas changer — chacun garde l'équipe que le jeu lui avait donnée.`r`n`r`nBEAUCOUP de règles plus bas ne servent à rien si tu ne changes pas les Pokémon."
    $Ui.Descriptions.TrainerMoves = "Choisit les quatre attaques des Pokémon des dresseurs.`r`n`r`n   4 attaques aléatoires — Pingoléon peut sortir n'importe quoi.`r`n   Attaques naturelles — celles qu'il connaîtrait à son niveau.`r`n   Stratégique Smogon — les attaques conseillées par les experts.`r`n`r`nEn mode Smogon, le menu juste à côté remplit les cases qui restent vides."
    $Ui.Descriptions.TrainerSmogonMoveFallback = "Dit quoi faire quand les experts ne donnent pas quatre attaques.`r`n`r`n   Attaques du niveau — on complète avec ce qu'il apprend en montant.`r`n   Au hasard — on complète avec des attaques tirées au sort.`r`n   Ne rien changer — on garde les attaques que le dresseur avait déjà.`r`n`r`nCe menu ne sert QUE si les attaques sont réglées sur Stratégique Smogon."
    $Ui.Descriptions.TrainerItems = "Choisit l'objet que tient chaque Pokémon d'un dresseur.`r`n`r`n   Seulement ceux qui en avaient un — les autres restent les mains vides.`r`n   Donner à tout le monde — même Pingoléon, qui n'avait rien, en reçoit un.`r`n   Tout enlever — plus personne ne tient quoi que ce soit.`r`n`r`nLe menu d'à côté décide dans quelle liste d'objets on va piocher."
    $Ui.Descriptions.TrainerItemPool = "Décide dans quelle liste on tire les objets tenus des dresseurs.`r`n`r`n   Combat — baies, Restes, plaques et autres objets utiles en combat.`r`n   Large — presque tout le jeu, y compris soins, menthes et bonbons.`r`n`r`nLes CT, les Poké Balls et les objets clés ne sortent JAMAIS. Sans effet si les objets tenus sont sur Ne pas changer."
    $Ui.Descriptions.TrainerAddedSlotSpecies = "Choisit les Pokémon ajoutés quand une équipe est agrandie.`r`n`r`n   Au hasard — n'importe qui débarque, même Empiflor.`r`n   Force proche — le nouveau venu a la force du reste de l'équipe.`r`n   Même type — chez un champion Plante, tu recevras un Pokémon Plante.`r`n`r`nCe menu ne sert QUE si les Pokémon des dresseurs sont sur Ne pas changer."
    $Ui.Descriptions.TrainerDuplicateMode = "Décide si un dresseur peut avoir deux fois la même chose.`r`n`r`n   Bloquer les doublons — jamais deux Pingoléon dans la même équipe.`r`n   Normal — le hasard fait ce qu'il veut, doublons compris.`r`n`r`nLe blocage vaut AUSSI pour les objets tenus. Sans effet sur un dresseur qui n'a qu'un Pokémon."
    $Ui.Descriptions.TrainerAbility = "Choisit le talent des Pokémon des dresseurs.`r`n`r`n   Au hasard — un des quatre emplacements de talent est tiré au sort.`r`n   Stratégique Smogon — le talent conseillé par les experts.`r`n   Ne pas changer — chacun garde le talent que le jeu lui donnait.`r`n`r`nSi les experts ne conseillent rien, un talent normal de l'espèce est choisi."
    $Ui.Descriptions.TrainerIV = "Règle les IV des dresseurs, le talent caché de chaque Pokémon.`r`n`r`n   31 partout — Pingoléon est parfait dans ses six statistiques.`r`n   Au hasard — chaque statistique tire un nombre entre 0 et 31.`r`n   Ne pas changer — on garde les valeurs du jeu.`r`n`r`nLe côté chromatique et le droit de Dynamaxer ne sont JAMAIS touchés."
    $Ui.Descriptions.TrainerEV = "Règle les EV, les points gagnés en s'entraînant au combat.`r`n`r`n   Stratégique Smogon — la répartition conseillée par les experts.`r`n   Au hasard mais valable — une répartition légale tirée au sort.`r`n   Tout à zéro — Empiflor n'a plus AUCUN entraînement.`r`n`r`nSi les experts n'ont rien pour cette espèce, une répartition au hasard prend le relais."
    $Ui.Descriptions.TrainerLevel = "Multiplie le niveau de tous les Pokémon des dresseurs.`r`n`r`n   1.20 — un Pingoléon niveau 25 passe autour du niveau 30.`r`n   0.80 — il redescend autour du niveau 20.`r`n   1.0 — les niveaux du jeu ne bougent pas.`r`n`r`nLe résultat reste entre 1 et 100. Les Pokémon sauvages ont leur PROPRE réglage."
    $Ui.Descriptions.TrainerTeamSize = "Impose un nombre minimum et maximum de Pokémon par dresseur.`r`n`r`n   Minimum 3 — un dresseur qui n'en avait qu'un en reçoit trois.`r`n   Maximum 4 — les grosses équipes redescendent à quatre.`r`n   -1 dans une case — cette limite n'est pas appliquée.`r`n`r`nOn ne dépasse JAMAIS six, et un minimum d'au moins un donne une équipe même à qui n'en avait pas."
    $Ui.Descriptions.TrainerTypeThemed = "Donne à chaque dresseur un SEUL type, tiré au sort, pour toute son équipe.`r`n`r`nUn dresseur tombé sur Eau n'enverra que des Pokémon Eau. Un dresseur tombé sur Plante peut sortir Empiflor. Chaque dresseur reçoit son propre type.`r`n`r`nIl faut que les Pokémon des dresseurs soient randomisés, sinon rien ne bouge."
    $Ui.Descriptions.TrainerExtraPokemon = "Ajoute des Pokémon en plus aux équipes, selon l'importance du dresseur.`r`n`r`n   Boss — champions d'arène, Conseil 4 et Maître.`r`n   Important — rivaux et chefs de l'équipe adverse.`r`n   Normal — tous les autres. Mets 0 pour ne rien ajouter.`r`n`r`nOn ne dépasse JAMAIS six, jamais plus de cinq ajoutés, et un dresseur sans équipe le reste."
    $Ui.Descriptions.TrainerSpecialRuleScope = "Choisit à qui s'appliquent les deux règles écrites à droite.`r`n`r`n   Arènes et Ligue — seulement les champions, le Conseil 4 et le Maître.`r`n   Tous les boss — on ajoute les rivaux et les chefs adverses.`r`n   Tout le monde — absolument chaque dresseur du jeu.`r`n`r`nLe menu Types variés a sa PROPRE portée et ne suit pas celui-ci."
    $Ui.Descriptions.TrainerLegendaryPolicy = "Décide combien de légendaires reçoivent les dresseurs choisis à gauche.`r`n`r`n   Aucun — ils disparaissent complètement de leurs équipes.`r`n   Un chacun — exactement un par équipe, le reste normal.`r`n   Que des légendaires — toute l'équipe. C'est vraiment TRÈS dur.`r`n`r`nEn exiger en donne même si la case Légendaires autorisés est décochée."
    $Ui.Descriptions.TrainerMinBaseStatTotal = "Oblige les dresseurs choisis à gauche à n'utiliser que des Pokémon assez forts.`r`n`r`nLe total additionne les six statistiques de base : Rattata fait 253, Dracaufeu 534, Mewtwo 680. Tape 600 et tu n'affrontes plus que des monstres, 0 pour arrêter.`r`n`r`nS'il reste moins de trois espèces au-dessus de la barre, les douze plus fortes sont gardées."
    $Ui.Descriptions.AllowLegendaryTrainers = "Coche pour que les dresseurs puissent recevoir des légendaires et des fabuleux.`r`n`r`nMewtwo, Zacian ou Mew peuvent alors se dresser en face de toi. Décochée, ils restent hors des équipes que le logiciel compose. Un légendaire déjà donné par le jeu reste à sa place.`r`n`r`nLa règle Que des légendaires passe OUTRE cette case et en donne quand même."
    $Ui.Descriptions.AllowLegendaryGrass = "Autorise les légendaires dans les hautes herbes et parmi les Pokémon visibles dehors.`r`n`r`nUn Empiflor de bord de lac peut devenir un Kyogre. Un Zacian peut se balader sur une route, visible de loin. Décochée, tu ne croises JAMAIS de légendaire sauvage.`r`n`r`nNe sert à rien si tu ne changes pas les Pokémon des hautes herbes."
    $Ui.Descriptions.AllowLegendaryStatic = "Autorise les légendaires pour les Pokémon que l'histoire pose à un endroit précis.`r`n`r`nCelui qui t'attend au fond d'une grotte peut devenir un Lugia. Un Pingoléon posé près d'un pont peut devenir un Rayquaza. Ces Pokémon se VOIENT avant que tu les touches.`r`n`r`nNe sert à rien si tu ne changes pas les rencontres fixes."
    $Ui.Descriptions.AllowLegendaryGifts = "Autorise les légendaires parmi les Pokémon qu'on t'offre, starters compris.`r`n`r`nLe Pokémon donné par un personnage peut devenir un Mew, et ton starter du début peut devenir un Zacian. Cadeaux et starters piochent dans la MÊME liste.`r`n`r`nNe sert à rien si tu ne changes ni les cadeaux ni les starters."
    $Ui.Descriptions.AllowLegendaryTrades = "Autorise les légendaires dans les échanges proposés par les personnages du jeu.`r`n`r`nLe Pokémon qu'on te réclame peut devenir un Kyogre, celui qu'on te donne en retour un Lugia. Les DEUX côtés de l'échange sont concernés.`r`n`r`nNe sert à rien si tu ne changes pas les échanges."
    $Ui.Descriptions.AllowLegendaryUnderground = "Autorise les légendaires dans les Aventures Dynamax de la Toundra Couronnée.`r`n`r`nUn Empiflor croisé dans une salle peut devenir un Necrozma, donc chaque salle peut cacher un légendaire. Les nids de raid de la Zone Sauvage ne sont PAS touchés.`r`n`r`nNe sert à rien si tu ne changes pas les Pokémon des Aventures Dynamax."
    $Ui.Descriptions.AllowLegendaryEvo = "Autorise les légendaires comme arrivée d'une évolution tirée au sort.`r`n`r`nTon Empiflor peut évoluer en Zacian, et un petit Pokémon du début peut mener tout droit à un Mewtwo. Décochée, AUCUNE évolution ne mène à un légendaire.`r`n`r`nÀ éviter si tu veux garder un début de partie équilibré."
    $Ui.Descriptions.AllowWonderGuard = "Autorise le talent Garde Mystik quand le logiciel mélange les talents.`r`n`r`nC'est le talent de Munja : SEULES les attaques super efficaces le blessent. Un Pingoléon avec Garde Mystik peut devenir impossible à battre.`r`n`r`nDécochée, seul Munja le garde. À cocher si tu aimes les mauvaises surprises."
    $Ui.Descriptions.MaxTrainerAI = "Donne à tous les dresseurs la MEILLEURE intelligence de combat du jeu.`r`n`r`nIls changent de Pokémon au bon moment, cherchent l'attaque qui te fait le plus mal et utilisent leurs soins quand il le faut.`r`n`r`nLes combats deviennent nettement plus durs sans qu'aucun Pokémon ne change."
    $Ui.Descriptions.ForceTrainerFullyEvolved = "Fait évoluer à fond les Pokémon des dresseurs à partir du niveau indiqué à droite.`r`n`r`nAu niveau 45, le Boustiflor d'un dresseur devient un Empiflor. En dessous, rien ne change. Quand plusieurs évolutions finales existent, une est tirée au hasard.`r`n`r`nPratique pour que les dresseurs de fin de jeu n'envoient plus des bébés."
    $Ui.Descriptions.ForceTrainerCanDynamax = "Permet à TOUS les dresseurs de Dynamaxer, pas seulement à ceux que le jeu autorisait.`r`n`r`nLe premier dresseur venu peut rendre son Pingoléon géant. Le Pokémon géant tient trois tours, comme d'habitude. Les formes Gigamax ne sont pas ajoutées.`r`n`r`nAttention : les combats ordinaires deviennent nettement plus durs."
    $Ui.Descriptions.TrainerDynamaxLevel = "Choisit le niveau Dynamax des Pokémon des dresseurs, donc leurs PV une fois géants.`r`n`r`n   Ne pas changer — chacun garde le niveau que le jeu lui donnait.`r`n   Niveau 10 — les PV DOUBLENT quand le Pokémon devient géant.`r`n   Au hasard de 0 à 10 — chaque Pokémon reçoit un niveau tiré au sort.`r`n`r`nMême au niveau 0, les PV augmentent quand même de moitié."
    $Ui.Descriptions.TrainerShinyChance = "Pourcentage de chance que chaque Pokémon de dresseur soit chromatique.`r`n`r`n   0 — aucun, comme dans le jeu normal.`r`n   5 — environ un Pingoléon de dresseur sur vingt brille.`r`n   100 — absolument TOUS les Pokémon de tous les dresseurs brillent.`r`n`r`nC'est joli, mais ça ne change rien à la force du Pokémon."
    $Ui.Descriptions.ForceBossTargets = "Liste des dresseurs comptés comme boss. Elle est là pour être LUE, pas remplie.`r`n`r`nElle change dès que tu modifies le choix des boss au-dessus, et te donne les noms exacts avant que tu lances la génération. Le tout premier combat de Nabil n'y est jamais.`r`n`r`nSi la case des boss à six est décochée, la liste te le dit à la place."
    $Ui.Descriptions.ValidateBuild = "Vérifie tes réglages et tes fichiers de jeu AVANT de lancer la génération.`r`n`r`nIl liste ce qui bloquerait, comme un dossier introuvable ou une option qui réclame l'ExeFS sans qu'il soit fourni."
    $Ui.Descriptions.BuildSummary = "Affiche en clair tout ce que tu as changé par rapport au jeu d'origine.`r`n`r`nÀ LIRE avant de générer : c'est le moyen le plus rapide de repérer une option activée par erreur."
    $Ui.Descriptions.UiLanguage = "Langue de cette fenêtre : français ou anglais.`r`n`r`nLe changement est IMMÉDIAT et aucun de tes réglages n'est perdu."
    $Ui.Descriptions.ReportLanguage = "Langue des fichiers de rapport écrits à côté de la run générée.`r`n`r`nElle est INDÉPENDANTE de la langue de cette fenêtre : tu peux lire l'interface en français et produire des rapports en anglais."
    $Ui.Descriptions.InstallTargetRyujinx = "Copie la run générée dans le dossier de mods de Ryujinx.`r`n`r`nFERME l'émulateur avant de générer : un fichier ouvert fait échouer la copie."
    $Ui.Descriptions.StarterMinBaseStatTotal = "Force MINIMALE des starters qu'on peut te proposer.`r`n`r`nCe total additionne les six statistiques : un starter du jeu tourne autour de 310. Mets 500 pour démarrer avec un Pokémon déjà costaud, 0 pour n'imposer aucun minimum.`r`n`r`nSans effet si tu as écrit les trois starters à la main. Si moins de trois rentrent, la borne saute."
    $Ui.Descriptions.StarterMaxBaseStatTotal = "Force MAXIMALE des starters qu'on peut te proposer.`r`n`r`nCe total additionne les six statistiques : un starter du jeu tourne autour de 310. Mets 350 pour éviter de commencer trop fort, 0 pour n'imposer aucun maximum.`r`n`r`nSans effet si tu as écrit les trois starters à la main. Si moins de trois rentrent, la borne saute."
    $Ui.Descriptions.EvolutionLimitToThreeStages = "Coupe toutes les chaînes d'évolution à TROIS Pokémon au maximum.`r`n`r`nUne fois les évolutions tirées au hasard, une chaîne peut en compter huit ou tourner en rond. Ici le troisième Pokémon d'une chaîne n'évolue plus du tout.`r`n`r`nSans évolutions randomisées il n'y a rien à couper : le jeu d'origine ne dépasse jamais trois."
    $Ui.Descriptions.FollowEvolutionsForTypes = "Donne à toute une famille les MÊMES types qu'à son premier Pokémon.`r`n`r`nSi Boustiflor devient Feu, l'Empiflor en lequel il évolue devient Feu aussi. Les familles suivies sont celles du jeu d'origine, même si tu as changé les évolutions.`r`n`r`nIl faut que le tirage des types soit activé, sinon cette option ne fait rien."
    $Ui.Descriptions.FollowEvolutionsForAbilities = "Donne à toute une famille les MÊMES talents qu'à son premier Pokémon.`r`n`r`nLes trois talents sont recopiés, le talent caché compris, donc évoluer ne te retire jamais un talent par surprise. Les familles suivies sont celles du jeu d'origine.`r`n`r`nIl faut que le tirage des talents soit activé, sinon cette option ne fait rien."
    $Ui.Descriptions.TrainerForceDiverseTypes = "Empêche un dresseur d'avoir deux Pokémon qui partagent un type.`r`n`r`nUne seule attaque super efficace ne peut plus balayer son équipe. Les dresseurs qui ont déjà un THÈME de type sont laissés tranquilles.`r`n`r`nQuand il ne reste plus aucun type libre, la règle s'arrête au lieu de bloquer."
    $Ui.Descriptions.WildLevelPercent = "Change le niveau de tous les Pokémon sauvages d'un pourcentage.`r`n`r`n   0 — ne change rien du tout.`r`n   50 — un Pingoléon niveau 20 passe au niveau 30.`r`n   -50 — il tombe au niveau 10, pour une partie plus facile.`r`n`r`nLes niveaux restent entre 1 et 100, et le plus petit reste TOUJOURS sous le plus grand."
    $Ui.Descriptions.EvolutionForceGrowth = "L'évolution doit être PLUS FORTE que la forme actuelle.`r`n`r`nÉquivaut au gain minimal réglé sur 1, et évite qu'un Pokémon régresse en évoluant. Pour choisir le seuil toi-même, sers-toi du gain minimal.`r`n`r`nSi les deux sont réglés, c'est le gain minimal qui l'emporte."
    $Ui.Descriptions.EvolutionSameType = "L'évolution garde un type EN COMMUN avec la forme de départ.`r`n`r`nPikachu, de type Électrik, peut devenir Raikou, également Électrik, mais jamais Magicarpe qui est de type Eau. Se cumule avec le gain minimal de statistiques.`r`n`r`nSi aucun Pokémon ne convient, le type est gardé en priorité et c'est le seuil qui est relâché."
    $Ui.Descriptions.MinimumCatchRate = "Rend tous les Pokémon au moins aussi faciles à attraper que le nombre que tu écris.`r`n`r`nCe nombre va de 0 à 255 : plus il est grand, plus la capture est facile. Mets 255 et presque n'importe quelle Ball attrape presque tout du premier coup. Mets 0 pour ne rien changer.`r`n`r`nUn Pokémon déjà plus facile garde sa valeur : ça ne rend JAMAIS une capture plus dure."
    $Ui.Descriptions.ExpCurveMode = "Choisit la vitesse à laquelle tous les Pokémon montent de niveau.`r`n`r`n   Tous rapides — tout le monde monte vite.`r`n   Tous lents — le jeu devient TRÈS long.`r`n   Tous moyens — une seule vitesse pour tous, ni rapide ni lente.`r`n`r`nNe pas changer laisse à chacun la vitesse qu'il a dans le jeu d'origine."
    $Ui.Descriptions.TutorCompatibilityMode = "Choisit quels Pokémon les 18 Maîtres de Capacités acceptent d'entraîner.`r`n`r`n   Une chance sur deux — pile ou face pour chaque maître sur chaque Pokémon.`r`n   Tout apprendre — les 18 maîtres entraînent tout le monde.`r`n`r`nPas de choix par type ici. Comme pour les CT et DT, ça ne change QUE le droit d'apprendre."
    $Ui.Descriptions.TmCompatibilityMode = "Choisit quels Pokémon ont le droit d'apprendre chacune des 200 CT et DT.`r`n`r`n   Une chance sur deux — pile ou face pour chaque machine sur chaque Pokémon.`r`n   Préférer le même type — une machine du type du Pokémon passe 9 fois sur 10.`r`n   Tout apprendre — tout le monde apprend tout. TRÈS puissant.`r`n`r`nÇa ne change pas ce qu'une machine enseigne, seulement qui a le droit de l'apprendre."
    $Ui.Descriptions.RandomizeWildHeldItems = "Change les objets que les Pokémon sauvages tiennent.`r`n`r`nTu peux les voler avec Larcin, ou les garder en capturant le Pokémon. SEULS ceux qui tenaient déjà un objet en reçoivent un nouveau.`r`n`r`nLes objets importants de l'aventure ne sont jamais donnés : ils pourraient bloquer ta partie."
    $Ui.Descriptions.ModOverworldShiny = "Montre les Pokémon chromatiques AVANT le combat, quand ils se promènent dehors.`r`n`r`nUn Pingoléon chromatique porte vraiment ses couleurs rares, un son joue et des étincelles apparaissent. Ça marche aussi sur les Pokémon qui mordent à la pêche.`r`n`r`nLes chances d'en croiser ne changent pas, sauf si tu remplis la case juste à côté."
    $Ui.Descriptions.OverworldShinyBoostPercent = "Force un pourcentage de Pokémon chromatiques parmi ceux qui apparaissent dehors.`r`n`r`n   0 — garde les chances normales du jeu, très faibles.`r`n   5 — environ un Pingoléon sur vingt est chromatique.`r`n   100 — ils sont TOUS chromatiques.`r`n`r`nÇa ne marche que si la case des chromatiques dehors est cochée."
    $Ui.Descriptions.ModUncapLevel = "Enlève la limite de niveau que tes badges imposent aux Pokémon sauvages.`r`n`r`nUn Pingoléon de haut niveau peut apparaître dès le début du jeu, et tu peux l'ATTRAPER alors que le jeu le refusait. Il peut même être chromatique.`r`n`r`nC'est surtout utile dans la Zone Sauvage, là où le jeu bloquait le plus."
    $Ui.Descriptions.ModUnderworld = "Fait sortir dehors les Pokémon des hautes herbes.`r`n`r`nCertains Pokémon ne vivent que dans les herbes et ne se montrent jamais. Ronflex et Ectoplasma, par exemple, ne se promènent jamais en temps normal.`r`n`r`nTu peux alors les VOIR et choisir de les affronter, au lieu de tomber dessus au hasard."
    $Ui.Descriptions.ModExtendedFollowing = "Garde visible le Pokémon qui te suit quand tu entres dans la Zone Sauvage.`r`n`r`nLe jeu le fait normalement DISPARAÎTRE dès que tu y mets un pied."
    $Ui.Descriptions.ModGlimwoodOverworld = "Fait apparaître des Pokémon visibles au Bois Chancelier, la forêt aux champignons lumineux.`r`n`r`nNormalement AUCUN ne s'y montre : tout se passe dans les herbes. Ici tu vois des Empiflor se promener entre les arbres.`r`n`r`nSeule cette forêt est concernée, le reste du jeu ne bouge pas."
    $Ui.Descriptions.GlimwoodMaxSpawns = "Combien de Pokémon peuvent se promener EN MÊME TEMPS au Bois Chancelier.`r`n`r`nPlus le nombre est haut, plus la forêt est peuplée, et plus ton émulateur travaille."
    $Ui.Descriptions.LearnsetMoveMode = "Change les attaques que chaque Pokémon apprend en montant de niveau.`r`n`r`n   Permuter — les mêmes attaques, redistribuées entre espèces. Aucune ne disparaît.`r`n   Au hasard — parmi les 610 attaques déjà apprises par niveau quelque part.`r`n   Tirage intégral — parmi les 787 attaques du jeu, même les plus rares.`r`n`r`nLes NIVEAUX ne bougent jamais : Pingoléon garde ses paliers, mais plus les mêmes coups."
    $Ui.Descriptions.TmMoveMode = "Change l'attaque enseignée par chacune des 200 CT et DT.`r`n`r`n   Permuter — les 200 mêmes attaques, mais plus sur les mêmes machines.`r`n   Au hasard — une attaque peut sortir deux fois et une autre disparaître.`r`n`r`nLes objets et leurs prix ne bougent pas. Ce réglage ne dit pas QUI peut apprendre : c'est la compatibilité qui s'en occupe."
    $Ui.Descriptions.ModDexAnimations = "Fait apparaître un Métamorph à côté de toi au chargement du terrain.`r`n`r`nParle-lui pour choisir une animation dans une liste : les Pokémon jouent ensuite celle-là à la place de la leur. C'est un jouet pour faire des images et des vidéos.`r`n`r`nIl n'apparaît qu'UNE FOIS par session : si tu l'as raté, relance le jeu."
    $Ui.Descriptions.ModFishingTweaks = "Garde ta série de pêche même quand un Pokémon brillant mord à l'hameçon.`r`n`r`nNormalement ce Pokémon brillant remet ta série à zéro. Ici tu continues à pêcher au même endroit sans RIEN perdre.`r`n`r`nÇa ne change ni les Pokémon pêchés ni leurs niveaux."
    $Ui.Descriptions.ModSynchroMode = "Te laisse promener toi-même le Pokémon qui te suit.`r`n`r`nAppuie sur L et R EN MÊME TEMPS pour passer de l'un à l'autre : ton personnage se cache et c'est le Pokémon qui bouge. Réappuie pour reprendre ton personnage.`r`n`r`nIl faut avoir un Pokémon qui te suit, sinon rien ne se passe."
    $Ui.Descriptions.ModCameraTweaks = "Libère la caméra : elle tourne plus vite, s'incline davantage et s'éloigne plus.`r`n`r`nTu peux reculer la vue pour voir toute une clairière d'un coup, ou l'incliner pour regarder devant toi. Ton personnage bouge exactement comme avant.`r`n`r`nLes réglages sont FIXES, tu n'as aucun nombre à saisir."
    $Ui.Descriptions.ModFreecam = "Détache la caméra de ton personnage pour la faire voler et regarder la carte.`r`n`r`nR et A ensemble la détachent puis la rattachent. La croix la déplace, ZL et ZR la font descendre ou monter, L et R changent sa vitesse.`r`n`r`nTon personnage reste SUR PLACE et ne bouge pas pendant ce temps."
    $Ui.Descriptions.RandomizeFieldItems = "Change les objets posés par terre, ceux que tu ramasses en marchant dessus.`r`n`r`nUne Potion au sol peut devenir une Pierre Feu, une Poké Ball peut devenir une CT. Il y en a 247 dans le jeu.`r`n`r`nLa boule au sol garde TOUJOURS la même apparence : seul ce qu'il y a dedans change."
    $Ui.Descriptions.RandomizeHiddenItems = "Change les objets invisibles, cachés dans le sol.`r`n`r`nTu marches au bon endroit et tu trouves quelque chose, sans jamais l'avoir vu avant. Il y en a plus de 4000 dans le jeu.`r`n`r`nMême idée que les objets posés par terre, mais ceux-là sont INVISIBLES."
    $Ui.Descriptions.FieldItemPoolMode = "Choisit ce que tu peux trouver par terre.`r`n`r`n   Sans objets clés — jamais d'objet de quête. Tu ne peux pas bloquer ta partie.`r`n   Tout — ajoute les CT et les DT. Tu peux trouver des attaques n'importe où.`r`n`r`nDans les deux cas, un objet que le jeu ne connaît pas n'est JAMAIS écrit."
    $Ui.Descriptions.ShopPriceMultiplier = "Change le prix des objets en boutique.`r`n`r`n   x2 — une Poké Ball à 200 coûte 400.`r`n   Gratuit — tout coûte 0, l'argent ne compte plus.`r`n   Aléatoire — chaque prix est tiré entre les deux bornes affichées.`r`n`r`nUn objet que le jeu ne vend jamais reste INVENDABLE. Seuls les prix changent, pas le stock."
    $Ui.Descriptions.RandomizeNatures = "Choisit la nature des Pokémon des dresseurs.`r`n`r`n   Ne pas changer — rien ne bouge.`r`n   Au hasard — une nature tirée parmi les 25.`r`n   Stratégique — celle qui va avec la panoplie choisie pour ce Pokémon.`r`n`r`nEn mode stratégique, attaques, objet, talent et EV viennent de la MÊME panoplie."
    $Ui.Descriptions.ForceAllTeams = "Donne SIX Pokémon à chaque dresseur du jeu.`r`n`r`nUn dresseur qui n'en avait que 2 en reçoit 4 de plus, autour du niveau moyen de son équipe d'origine. Ils passent ensuite par tes autres réglages, comme le reste.`r`n`r`nUn dresseur sans aucun Pokémon n'en reçoit pas : on ne crée pas de combats."
    $Ui.Descriptions.ForceBossTeams = "Fait passer à SIX Pokémon les équipes des boss choisis dans le menu juste à côté.`r`n`r`nUn champion qui n'en alignait que trois en aligne six. Les Pokémon ajoutés suivent les mêmes règles que les autres, et les dresseurs ordinaires ne sont pas touchés.`r`n`r`nInutile si tu as déjà mis toutes les équipes du jeu à six."
    $Ui.Descriptions.BossTeamsScope = "Choisit quels dresseurs comptent comme boss pour l'option juste au-dessus.`r`n`r`n   Boss importants — les arènes, plus les rivaux et les grands combats de l'histoire.`r`n   Arènes et ligue seulement — champions, combats de ligue et Tarak.`r`n`r`nLa liste à droite se met à jour tout de suite : tu vois exactement qui est pris."
    $Ui.Descriptions.TypeMode = "Retire à chaque Pokémon ses types et lui en donne d'autres au hasard.`r`n`r`nPingoléon peut devenir Plante et Poison, Empiflor peut devenir Feu. Environ quatre fois sur dix il n'a plus qu'UN SEUL type. Les faiblesses et le bonus d'attaque suivent les nouveaux types.`r`n`r`nLa case à côté sert à donner un seul type à tout le monde, sans exception."
    $Ui.Descriptions.TypesMonotypeOnly = "Donne un SEUL type à chaque Pokémon au lieu de deux.`r`n`r`nPingoléon devient Feu tout court, jamais Feu et Acier. Plus aucun Pokémon du jeu n'a de double type, et les faiblesses deviennent bien plus simples à retenir.`r`n`r`nNe fait rien si le menu à côté est réglé sur ne pas changer les types."
    $Ui.Descriptions.AbilityMode = "Change les talents des Pokémon, ces pouvoirs qui agissent tout seuls en combat.`r`n`r`nLes trois talents possibles d'une espèce sont tirés au hasard. Empiflor peut hériter du talent d'un Pokémon complètement différent, et TOUS les Empiflor du jeu recevront les mêmes.`r`n`r`nGarde Mystik est écarté par défaut : la case à côté permet de l'autoriser."
    $Ui.Descriptions.StatMode = "Change les six statistiques de base de chaque Pokémon.`r`n`r`n   Mélanger — les six chiffres de Pingoléon sont remis dans un autre ordre.`r`n   Redistribuer — le total reste le même, tout est réparti autrement.`r`n   Ne pas changer — les statistiques restent celles du jeu.`r`n`r`nDans les deux cas le TOTAL ne bouge pas : un Pokémon fort reste fort, autrement."
    $Ui.Descriptions.ExpYieldMultiplier = "Multiplie toute l'expérience que tu gagnes en combat.`r`n`r`n   2.5 — un combat qui rapportait 400 points en rapporte environ 1000.`r`n   0.5 — tu montes deux fois moins vite.`r`n   1.0 — tu gardes l'expérience normale du jeu.`r`n`r`nCe réglage a besoin du mod installé. La case Un seul point à côté prend le DESSUS."
    $Ui.Descriptions.ForceOneExpYield = "Fait qu'un Pokémon battu ne rapporte plus qu'UN SEUL point d'expérience.`r`n`r`nUn Empiflor qui donnait 350 points n'en donne plus qu'un, et tes Pokémon ne montent presque plus de niveau. Pas besoin du mod : c'est écrit directement dans le jeu.`r`n`r`nCochée, cette case annule le multiplicateur d'expérience juste à côté."
    $Ui.Descriptions.MoveTypeMode = "Tire au hasard le type de chaque attaque du jeu.`r`n`r`nTonnerre peut devenir une attaque de type Feu. Les faiblesses et le bonus de type suivent le nouveau type, et même les attaques de statut changent.`r`n`r`nPingoléon peut alors n'avoir PLUS UNE SEULE attaque qui colle à ses propres types."
    $Ui.Descriptions.MovePowerMode = "Tire au hasard la puissance de chaque attaque qui fait des dégâts.`r`n`r`nCharge peut passer de 40 à 130. Hydrocanon peut tomber à 25 et ne presque plus faire mal. Les deux cases à côté fixent le minimum et le maximum, 20 et 150 au départ.`r`n`r`nLes attaques de statut, qui ne font pas de dégâts, ne sont JAMAIS touchées."
    $Ui.Descriptions.MovePPMode = "Tire au hasard les PP de chaque attaque, donc combien de fois tu peux t'en servir.`r`n`r`nUne attaque à 15 PP peut tomber à 5 ou monter à 40. TOUTES les attaques sont concernées. Les deux cases à côté fixent le minimum et le maximum, 5 et 40 au départ.`r`n`r`nAvec un minimum très bas, tu passeras beaucoup de temps au Centre Pokémon."
    $Ui.Descriptions.MoveAccuracyMode = "Tire au hasard la précision de chaque attaque, sa chance de toucher.`r`n`r`nHydrocanon peut devenir sûr et ne plus jamais rater. Charge peut se mettre à rater une fois sur trois. Les deux cases à côté fixent le minimum et le maximum, 70 et 100 au départ.`r`n`r`nLes attaques de statut sont concernées AUSSI, comme Cage-Éclair."
    $Ui.Descriptions.MoveCategoryMode = "Décide si une attaque tape avec l'Attaque ou avec l'Attaque Spéciale.`r`n`r`nLance-Flammes peut devenir physique, Tête de Fer peut devenir spéciale. SEULES les attaques qui font des dégâts sont concernées.`r`n`r`nUn Pokémon costaud au corps à corps peut hériter d'attaques qui ne lui vont plus."
    $Ui.Descriptions.StarterMode = "Change les trois starters que le jeu te propose au début.`r`n`r`n   Au hasard — Ouistempo peut devenir Pingoléon.`r`n   Force proche — les trois gardent une force voisine de l'originale.`r`n   Ne pas changer — tu gardes Ouistempo, Flambino et Larméléon.`r`n`r`nSi tu remplis les trois cases à la main, il en faut TROIS, et trois espèces différentes."
    $Ui.Descriptions.Starter1 = "Premier starter imposé.`r`n`r`nRemplis les TROIS champs pour choisir exactement ton trio, ou laisse-les vides pour laisser le mode du dessus décider. Les noms français et anglais sont acceptés."
    $Ui.Descriptions.Starter2 = "Deuxième starter imposé.`r`n`r`nLes trois champs vont ENSEMBLE : trois remplis imposent le trio, trois vides rendent la main au mode du dessus."
    $Ui.Descriptions.Starter3 = "Troisième starter imposé.`r`n`r`nTape le nom tel qu'il apparaît en jeu, en français ou en anglais. Les trois champs doivent désigner trois espèces DIFFÉRENTES."
    $Ui.Descriptions.PatchStarters = "Met à jour les dresseurs qui possédaient un starter d'origine, après ton nouveau trio.`r`n`r`n   Nabil avait Ouistempo — il reçoit ton premier nouveau starter.`r`n   Les formes évoluées suivent — Gorythmic devient ce même Pokémon de base.`r`n`r`nLeurs quatre attaques sont refaites pour aller avec. À LAISSER cochée, sinon ils gardent un starter que tu n'as plus."
    $Ui.Descriptions.EvolutionMode = "Change en quoi chaque Pokémon évolue.`r`n`r`n   Au hasard — Ponyta peut évoluer en Pingoléon.`r`n   Force proche — l'évolution garde une force voisine, à 55 points près.`r`n   Ne pas changer — les évolutions restent celles du jeu.`r`n`r`nLes niveaux et les conditions ne changent pas ici : les réglages en dessous s'en occupent."
    $Ui.Descriptions.NormalizeFriendship = "Remplace les évolutions par amitié par une évolution à un niveau FIXE que tu choisis.`r`n`r`nÉvoli n'a plus besoin de t'aimer : il évolue au niveau écrit à côté. Riolu devient Lucario en montant de niveau, sans câlins. Les versions du jour et de la nuit sont traitées pareil.`r`n`r`nPratique : l'amitié est très longue à monter dans une partie rapide."
    $Ui.Descriptions.NormalizeTrade = "Remplace les évolutions par échange par une évolution à un niveau FIXE que tu choisis.`r`n`r`nMachopeur devient Mackogneur tout seul, sans ami pour l'échanger. Spectrum devient Ectoplasma en montant simplement de niveau. Les échanges avec un objet à tenir marchent pareil.`r`n`r`nIndispensable si tu joues seul : sinon ces évolutions sont IMPOSSIBLES."
    $Ui.Descriptions.NormalizeSpecial = "Remplace toutes les autres conditions d'évolution par un simple niveau à atteindre.`r`n`r`nPlus besoin d'un lieu précis, d'une heure, de la météo, d'une pierre, d'une attaque connue ni d'un objet tenu. Si les deux cases du dessus sont décochées, amitié et échange y passent AUSSI.`r`n`r`nLes évolutions qui marchaient déjà au niveau gardent celui du jeu."
    $Ui.Descriptions.NpcGiftItemMode = "Change les objets que les personnages te donnent.`r`n`r`n   Permuter — les cadeaux s'échangent entre les personnages.`r`n   Aléatoire — chaque cadeau devient n'importe quel objet.`r`n`r`nLes objets clés ne sont JAMAIS touchés : Vélo Rotom, Bracelet Dynamax, Recommandation. En changer un rendrait ta partie infinissable."
    $Ui.Descriptions.GiftMode = "Change les Pokémon qu'on t'offre pendant l'aventure.`r`n`r`n   Au hasard — le Toxizap offert peut devenir Empiflor.`r`n   Force proche — le cadeau garde une force voisine.`r`n   Ne pas changer — tu reçois les cadeaux prévus par le jeu.`r`n`r`nLes trois starters ne sont PAS concernés : ils ont leur propre menu à côté."
    $Ui.Descriptions.TradeMode = "Change les Pokémon des échanges avec les personnages du jeu.`r`n`r`n   Au hasard — on te réclame Pingoléon et on te rend Empiflor.`r`n   Force proche — les deux gardent une force voisine.`r`n   Ne pas changer — les échanges restent ceux du jeu.`r`n`r`nLes DEUX côtés changent. Attention : il faut vraiment posséder le Pokémon demandé."
    $Ui.Descriptions.StaticMode = "Change les Pokémon des rencontres fixes, celles que l'histoire te pose devant toi.`r`n`r`n   Au hasard — le légendaire du scénario peut devenir Empiflor.`r`n   Force proche — le remplaçant garde une force voisine.`r`n   Ne pas changer — ces rencontres ne bougent pas.`r`n`r`nLe menu en dessous décide si deux rencontres identiques donnent le même remplaçant."
    $Ui.Descriptions.StaticStableMapping = "Décide si deux rencontres fixes identiques donnent le même remplaçant.`r`n`r`n   Par espèce — tous les Pingoléon fixes deviennent le même Pokémon.`r`n   Par emplacement — chaque rencontre est tirée séparément, sans rien retenir.`r`n`r`nInutile si les rencontres fixes ne changent pas. En mode par espèce, les herbes SUIVENT."
    $Ui.Descriptions.GrassMode = "Change les Pokémon sauvages qu'on croise dans les hautes herbes.`r`n`r`n   Au hasard — un Rongourmand peut devenir Pingoléon.`r`n   Force proche — le remplaçant garde une force voisine, à 55 points près.`r`n   Ne pas changer — les herbes ne bougent pas.`r`n`r`nLes deux menus en dessous décident de ce que tu VOIS dehors et de ce que tu COMBATS."
    $Ui.Descriptions.GrassStableMapping = "Décide comment les tables de rencontres sauvages sont réécrites.`r`n`r`n   Par slot — chaque emplacement est tiré SÉPARÉMENT : un Empiflor d'une zone peut devenir Pingoléon pendant que celui du slot d'à côté devient autre chose.`r`n   Par espèce — dans une même zone et une même table, tous les Empiflor deviennent le MÊME remplaçant.`r`n`r`nPar espèce garde une partie lisible, par slot est le mode chaotique. Sans effet si les Pokémon des hautes herbes sont sur Ne pas changer."
    $Ui.Descriptions.VisibleEncounterBehavior = "Réglage REMPLACÉ : ce sont les deux listes du dessous qui décident.`r`n`r`nUne pour ce que tu vois, une pour ce que tu affrontes. Ce choix-ci n'a plus qu'un effet marginal sur les fichiers copiés, et il est masqué pour ne pas t'induire en erreur.`r`n`r`nSers-toi des menus Pokémon visibles et Pokémon affrontés à la place."
    $Ui.Descriptions.EncounterDrawMode = "Choisit comment le remplaçant est tiré.`r`n`r`n   Slot par espèce — un Pingoléon donne toujours le même remplaçant dans une zone.`r`n   Tirage complet — un nouveau remplaçant à chaque rencontre.`r`n`r`nAvec le premier tu peux APPRENDRE la zone. Avec le second tu ne peux rien prévoir."
    $Ui.Descriptions.LiveVisibleMode = "Change les Pokémon que tu VOIS te promener dehors.`r`n`r`n   Inchangé — ceux du jeu d'origine.`r`n   Aléatoire — un nouveau à chaque apparition.`r`n   Par zone — chaque zone garde les siens.`r`n   Découverte — l'herbe reste vanilla jusqu'à ce qu'un combat révèle l'espèce.`r`n   Découverte, herbe aléatoire — pareil, mais un leurre tiré au sort remplace le vanilla.`r`n`r`nDans les DEUX : tu affrontes un Empiflor, et Empiflor se promène là pour de bon. Seul ce que tu vois AVANT ce premier combat change."
    $Ui.Descriptions.LiveBattleMode = "Change les Pokémon que tu AFFRONTES vraiment.`r`n`r`nRéglé différemment du visible, tu obtiens le combat caché : tu vois un Pingoléon et tu affrontes un Empiflor. Voir un Pokémon dehors ne dit plus lequel tu auras.`r`n`r`nC'est le réglage des Nuzlocke : impossible de choisir sa capture à vue."
    $Ui.Descriptions.AllowLegendaryLiveVisible = "Autorise les légendaires parmi les Pokémon que tu VOIS te promener dehors.`r`n`r`nUn Zacian peut apparaître à la place d'un Pingoléon. Seuls ceux que le jeu sait montrer dehors peuvent sortir. Celui que tu affrontes dépend de la case juste à côté.`r`n`r`nNe sert à rien si tu ne changes pas les Pokémon visibles dehors."
    $Ui.Descriptions.AllowLegendaryLiveBattle = "Autorise les légendaires parmi les Pokémon que tu AFFRONTES vraiment.`r`n`r`nTu vois un Pingoléon dans l'herbe et tu tombes sur un Mewtwo. TOUS les légendaires sont possibles, même ceux qu'on ne voit jamais dehors.`r`n`r`nNe sert à rien si tu ne changes pas les Pokémon affrontés."
    $Ui.Descriptions.OverworldVisibleMaxHitbox = "Évite que des Pokémon encombrants te bouchent la vue dehors.`r`n`r`nOn se sert du rayon de collision DU JEU, pas de la taille du Pokédex : Rayquaza est enroulé et ne pèse que 70, alors que Léviator en fait 220. La médiane des 664 espèces est à 47, les plus gros sont Wailord et Onix à 400.`r`n   Sans les colosses — retire 4 espèces.`r`n   Sans les très gros — en retire 7.`r`n   Sans les gros — en retire 31, Léviator compris.`r`n   Compact — en retire 85.`r`n`r`nCa ne touche QUE ce que tu vois. Tu peux toujours les affronter, et un colosse déjà révélé en mode Découverte continuera de se promener dans sa zone."
    $Ui.Descriptions.OverworldVisiblePoolMode = "Décide QUELLES espèces ont le droit d'apparaître dehors.`r`n`r`n   Toutes les espèces — les 664 jouables. C'est le défaut.`r`n   Prévues pour être dehors — retour aux 330 que le jeu utilise lui-même.`r`n   TEST : uniquement les non prévues — ne garde QUE celles que le jeu ne montre jamais dehors.`r`n`r`nVérifié en jeu le 2026-09-09 : Persian et Muplodocus, que Épée/Bouclier ne montrent JAMAIS dehors, apparaissent correctement et peuvent être affrontés. Le plafond de 330 était un choix de contenu, pas une limite du moteur."
    $Ui.Descriptions.LiveGenerationFilter = "Limite les Pokémon à certaines générations.`r`n`r`nÉcris les numéros séparés par des virgules, comme 1,2,8. Laisse VIDE pour n'imposer aucune limite. Écris 1 tout seul pour n'avoir que la première génération.`r`n`r`nCe filtre vaut pour tout par défaut. Les trois cases plus bas permettent d'en donner un différent selon les cas."
    $Ui.Descriptions.GenerationFilterVisible = "ATTENTION : ce réglage n'a JAMAIS été vu marcher, ni sur Épée ni sur Bouclier.`r`n`r`nIl limite les générations de ce que tu VOIS dehors, et suit le filtre général s'il est vide. En mode Découverte il ne peut rien faire : l'herbe reste celle du jeu.`r`n`r`nSers-toi du filtre général si tu veux un résultat sûr."
    $Ui.Descriptions.GenerationFilterBattle = "Limite les générations de ce que tu AFFRONTES.`r`n`r`nLaisse vide pour suivre le filtre général. Vaut pour les hautes herbes, les rencontres fixes et le souterrain. Tu peux voir de la 1re génération et affronter de la 2e.`r`n`r`nC'est ce réglage qui décide de ce que tu peux CAPTURER."
    $Ui.Descriptions.GenerationFilterGifts = "Limite les générations de ce qu'on te DONNE.`r`n`r`nLaisse vide pour suivre le filtre général. Vaut pour les cadeaux, les starters et les échanges. Écris 1 et on ne te donnera que de la première génération.`r`n`r`nLaisse le filtre des équipes vide et tu obtiens joueur en 1re génération, adversaires en tout."
    $Ui.Descriptions.GenerationFilterTrainers = "Limite les générations des ÉQUIPES adverses.`r`n`r`nLaisse vide pour suivre le filtre général, et les dresseurs peuvent alors tout sortir. Écris 1 et ils n'auront que de la première génération.`r`n`r`nIndépendant de ce que toi tu peux attraper."
    $Ui.Descriptions.EvolutionMinBstGain = "Exige que l'évolution soit au moins aussi forte que la forme de départ.`r`n`r`n   -1 — aucune règle, l'évolution peut être plus faible.`r`n   0 — au moins équivalente.`r`n   10 — au moins 10 points de statistiques de plus.`r`n`r`nC'est un PLANCHER, pas une cible : un Pokémon bien plus fort reste possible."
    $Ui.Descriptions.OverworldModelSafeEncounters = "Reste sur les Pokémon que le jeu montre déjà dehors.`r`n`r`n   Coché — seules les espèces qui se promènent en temps normal.`r`n   Décoché — n'importe quelle espèce peut apparaître.`r`n`r`nTouche les rencontres fixes et le souterrain. Décoché par défaut : la garantie annoncée ne tenait pas."
    $Ui.Descriptions.WriteInstallationPackage = "Crée le dossier Installation, prêt à copier.`r`n`r`n   Coché — un dossier par émulateur, prêt à coller.`r`n   Décoché — génération plus rapide.`r`n`r`nTa ROM est complète dans le dossier de sortie DANS LES DEUX CAS. C'est une copie de confort de 6210 fichiers."
    $Ui.Descriptions.StrictDataFiles = "Arrête tout si un fichier de données manque.`r`n`r`n   Coché — la génération échoue au lieu de continuer.`r`n   Décoché — elle continue et signale ce qui manque.`r`n`r`nUtile pour vérifier une installation. Sans ces fichiers, les rapports affichent des NUMÉROS au lieu des noms."
    $Ui.Descriptions.RandomizeTrainerNatures = "Donne une nature au hasard aux Pokémon des dresseurs.`r`n`r`nLa nature change deux statistiques : une monte, une baisse. Un Pingoléon Rigide frappe plus fort mais attaque moins vite. Ça ne touche QUE les adversaires, jamais ton équipe.`r`n`r`nEffet discret pris séparément, net sur un combat entier."
    $Ui.Descriptions.TrainerBagItemMode = "Change ce que les dresseurs ont dans leur sac.`r`n`r`n   Sac vide — plus AUCUN dresseur ne soigne son Pokémon.`r`n   Au hasard — d'autres objets, du même genre.`r`n`r`n52 dresseurs sur 437 en portent un. Sans cette option, un champion peut annuler tout un combat avec une Guérison."
    $Ui.Descriptions.ShopItemMode = "Choisit ce qui peut remplacer un objet en boutique.`r`n`r`n   Même genre — une ball devient une ball, un soin devient un soin.`r`n   Tout ce que la boutique vend — elle mélange ses propres rayons.`r`n`r`nAUCUN mode ne met en vente un objet d'un rayon que la boutique ne connaît pas : c'est ce qui vidait la liste."
    $Ui.Descriptions.UndergroundMode = "Change les Pokémon des zones souterraines, qui ont leur propre liste.`r`n`r`n   Au hasard — n'importe quelle espèce peut sortir de terre.`r`n   Force proche — le remplaçant garde une force voisine.`r`n   Ne pas changer — rien ne change sous terre.`r`n`r`nC'est une liste À PART : changer les hautes herbes ne touche pas à celle-ci."
    $Ui.Descriptions.DisableExpShare = "Éteint le partage d'expérience au départ : seuls les Pokémon qui COMBATTENT en gagnent.`r`n`r`n   Coché — le partage démarre éteint.`r`n   Décoché — il démarre allumé, comme d'habitude.`r`n`r`nTon équipe monte moins vite et tu dois faire tourner tes Pokémon. Ne marche que si le mod est bien installé."
    $Ui.Descriptions.EarlyBike = "NÉCESSITE EXEFS. Te donne le Vélo Rotom dès le début de la partie.`r`n`r`nLe module te le remet UNE SEULE FOIS, au premier chargement du terrain sur une sauvegarde."
    $Ui.Descriptions.RuntimePcControls = "Ajoute un menu quand tu utilises le PC d'un Centre Pokémon.`r`n`r`nIl affiche l'état du partage d'EXP et du boost d'EXP, que tu peux changer en PLEINE partie sans refaire une ROM. Les Boîtes, le Poké Service et le Studio Carte restent accessibles.`r`n`r`nElle ne choisit aucun réglage toute seule : elle ouvre juste le menu."
    $Ui.Descriptions.DynamicExpLevelCap = "NÉCESSITE EXEFS. Bloque l'expérience au-dessus d'un niveau plafond qui monte avec ta progression.`r`n`r`nUn Pokémon arrivé au plafond ne gagne plus qu'UN point d'expérience ; ceux qui sont en dessous montent normalement."
    $Ui.Descriptions.StrictBossMaxLevelCap = "NÉCESSITE EXEFS. Fixe le plafond sur le Pokémon le plus fort du prochain boss.`r`n`r`nSi ce boss aligne un Pokémon niveau 28, tu ne dépasses PAS 28 avant de l'avoir battu."
    $Ui.Descriptions.MainStorySoftLevelCap = "NÉCESSITE EXEFS. Plafond de niveau qui suit l'histoire principale.`r`n`r`nMesuré sur Épée : dans chaque bloc de badges, le champion d'arène est toujours le combat le plus fort. Ce plafond tombe donc sur les MÊMES valeurs que le cap arènes."
    $Ui.Descriptions.GymLeagueStoryLevelCap = "NÉCESSITE EXEFS. Bloque ton niveau sur celui des arènes et de Tarak.`r`n`r`nLes plafonds sont lus sur les équipes RÉELLEMENT générées, pas sur celles du jeu d'origine."
    $Ui.Descriptions.StoryMajorBattleOrderLevelCap = "NÉCESSITE EXEFS. Plafond de niveau qui suit l'ordre des grands combats.`r`n`r`nNabil, Travis, Rosemary, les champions, Shehroz puis Tarak sont replacés dans l'ORDRE de l'histoire, et les plafonds suivent cette séquence."
    $Ui.Descriptions.AutoInstallToEden = "Copie le mod fini directement dans tes émulateurs, sans un seul fichier à déplacer.`r`n`r`nSeuls les émulateurs à la fois COCHÉS et détectés sur ton disque reçoivent la copie.`r`n`r`nFerme-les avant de générer : un fichier ouvert fait échouer la copie."
    $Ui.Descriptions.EdenModName = "Nom du dossier créé dans tes émulateurs.`r`n`r`nGarde le MÊME nom et chaque génération remplace la précédente. Change-le, par exemple en MaRun2, et tu conserves les deux mods côte à côte."
}

function Get-UiStrings {
    param([string]$Language = "fr")

    if ($Language -eq "en") {
        return @{
            FormTitle = "PokeFeur Randomizer SWSH $AppVersion"
            SourceLabel = "Original ROMFS folder"
            SourceExefsLabel = "Original ExeFS folder"
            OutputLabel = "Generated mod folder"
            GameVersion = "Target game"
            Browse = "Browse"
            Seed = "Seed (-1 = auto)"
            UiLanguage = "Software language"
            ReportLanguage = "JSON report language"
            Theme = "Theme"
            ValidateBuild = "Check config"
            BuildSummary = "Build summary"
            Generate = "Generate mod"
            Tabs = @{ General = "Build"; Trainers = "Trainers"; Pokemon = "Pokémon"; Evolutions = "Evolutions"; Gifts = "Starters / gifts"; Encounters = "Encounters"; Comfort = "Comfort / extras"; Help = "Help"; Reset = "Clean install" }
            GeneralLines = @(
                "Complete build: user ROMFS + user ExeFS, ExLaunch, JSON presets, detailed reports, and emulator auto-install.",
                "BST = the sum of the 6 base stats. Similar BST keeps replacements in a comparable power range.",
                "Trainers: species, moves, items, IV/EV, shiny, AI, Dynamax, team size, and boss teams at 6.",
                "Pokemon: types, abilities, stats, EXP yield, global moves, and evolutions.",
                "Encounters: static, wild, visible, underground, stable mappings, and hidden battle rolls.",
                "Starters: French/English names accepted, example Victreebel / Empoleon / Victreebel.",
                "EXP caps: runtime modes require ExLaunch and export their JSON cap tables."
            )
            ModeRandom = "Full random"
            ModeSimilarBST = "Balanced random (similar BST)"
            ModeUnchanged = "Keep vanilla"
            MappingSlot = "Stable by slot"
            MappingSpecies = "Stable by species"
            ModeVanillaGame = "Unchanged (the game's own)"
            DrawRandom = "Random draw"
            BagEmpty = "Empty bag (no healing item)"
            BagRandom = "Random items"
            ScopeOff = "Off"
            ScopeGymLeague = "Gyms + League"
            ScopeAllBosses = "All bosses"
            ScopeEveryone = "Everyone"
            LegendaryPolicyUnchanged = "Do not enforce"
            LegendaryPolicyNone = "No legendary"
            LegendaryPolicyOneEach = "One legendary each"
            LegendaryPolicyAll = "Legendaries only"
            LearnsetShuffle = "Shuffle between species"
            LearnsetFullRandom = "Full draw (every move)"
            ShopItemSamePocket = "Same kind of item"
            ShopItemFullRandom = "Anything the shop sells"
            ShopPriceFree = "Free (x0)"
            ShopPriceHalf = "Half price (x0.5)"
            ShopPriceNormal = "Normal prices (x1)"
            ShopPriceDouble = "Double (x2)"
            ShopPriceExpensive = "Very expensive (x5)"
            ShopPriceRandomSmall = "Random (100 - 5,000)"
            ShopPriceRandomMedium = "Random (300 - 20,000)"
            ShopPriceRandomWide = "Random (1 - 999,999)"
            FieldPoolSafe = "No key items"
            FieldPoolAll = "Everything, TMs and TRs included"
            NpcGiftShuffle = "Shuffle between NPCs"
            LiveRandomSpawn = "Random on every spawn"
            LiveRandomBattle = "Random on every battle"
            LiveStableZone = "Stable per zone"
            LiveStableGlobal = "Stable everywhere"
            LiveDiscovery = "Zone discovery"
            LiveDiscoveryRandom = "Discovery, random grass"
            OverworldPoolVanilla = "Seen in vanilla (the base 330)"
            OverworldPoolAll = "Every species"
            OverworldPoolUnusual = "TEST: only the unintended ones"
            HitboxNone = "No limit"
            HitboxColossal = "No colossal ones"
            HitboxVeryLarge = "No very large ones"
            HitboxLarge = "No large ones"
            HitboxCompact = "Compact only"
            ExpCurveFast = "All fast"
            ExpCurveMedium = "All medium"
            ExpCurveSlow = "All slow"
            TmShuffle = "Shuffle between machines"
            CompatHalf = "One chance in two"
            CompatSameType = "Prefer the same type"
            CompatFull = "Learn everything"
            TrainerMoveRandom4 = "4 random moves"
            TrainerMoveLevel4 = "Natural moves for its level"
            TrainerMoveSmogon = "Smogon strategic"
            TrainerMoveSmogonLegacy = "Smogon + older gens"
            TrainerSmogonMoveFallbackLevel = "Fallback: natural level moves"
            TrainerSmogonMoveFallbackRandom = "Fallback: random moves"
            TrainerSmogonMoveFallbackUnchanged = "Fallback: keep vanilla"
            TrainerItemRandomPresent = "Random when an item is already present"
            TrainerItemForceAll = "Random item on every trainer Pokemon"
            TrainerItemSmogon = "Smogon strategic item"
            TrainerItemSmogonLegacy = "Smogon item + older gens"
            TrainerItemRemoveAll = "Remove all held items"
            TrainerItemPoolBattle = "Battle pool (useful held items)"
            TrainerItemPoolFull = "Wide safe pool (chaotic)"
            TrainerAddedSlotRandom = "Added slots: full random"
            TrainerAddedSlotSimilarBST = "Added slots: similar BST"
            TrainerAddedSlotSameType = "Added slots: same type"
            TrainerAddedSlotSameTypeBST = "Added slots: same type + BST"
            TrainerDuplicateNoDuplicates = "Block duplicates"
            TrainerDuplicateNormal = "Normal random (duplicates possible)"
            BossScopeMajor = "Major bosses"
            BossScopeGymLeague = "Gyms + league only"
            TrainerAbilityRandom = "Randomize trainer ability slot"
            TrainerAbilitySmogon = "Smogon strategic ability"
            TrainerAbilitySmogonLegacy = "Smogon ability + older gens"
            TrainerIVMax = "31 in every IV"
            TrainerIVRandom = "Random"
            TrainerEVSmogon = "Smogon strategic EVs"
            TrainerEVSmogonLegacy = "Smogon EVs + older gens"
            TrainerEVRandom = "Random legal EVs"
            TrainerEVZero = "Set EVs to zero"
            TrainerNatureUnchanged = "Keep vanilla nature"
            TrainerNatureRandom = "Random nature"
            TrainerNatureSmogon = "Smogon strategic nature"
            TrainerNatureSmogonLegacy = "Smogon nature + older gens"
            StarterRandom = "Random starter Pokemon"
            StarterSimilarBST = "Similar BST starter Pokemon"
            StarterUnchanged = "Do not change starter Pokemon"
            StatShuffle = "Shuffle the 6 stats"
            StatRedistribute = "Redistribute BST"
            ReportLanguageFrench = "French"
            ReportLanguageEnglish = "English"
            UiLanguageFrench = "Francais"
            UiLanguageEnglish = "English"
            ThemeLight = "Light"
            ThemeDark = "Dark"
            Labels = @{
                TrainerSpecies = "Trainer Pokemon species"
                TrainerMoves = "Trainer Pokemon moves"
                TrainerSmogonMoveFallback = "Smogon move fallback"
                TrainerItems = "Trainer held items"
                TrainerItemPool = "Random item pool"
                TrainerAddedSlotSpecies = "Pokemon added to 6-slot teams"
                TrainerDuplicateMode = "Team duplicates"
                TrainerAbility = "Trainer Pokemon abilities"
                TrainerIV = "Trainer IVs"
                TrainerEV = "Trainer EVs"
                TrainerLevel = "Trainer level multiplier"
                TrainerTeamMin = "Min team size"
                TrainerTeamMax = "Max team size"
                TrainerTypeThemed = "Type-themed trainer teams"
                TrainerShinyChance = "Trainer shiny rate (%)"
                ForceTrainerFullyEvolved = "Force final evolutions"
                TrainerFullyEvolvedLevel = "Final evolution level"
                MaxTrainerAI = "Max trainer AI"
                TrainerDynamaxLevel = "Trainer Dynamax level"
                TrainerDynamaxUnchanged = "Do not change"
                TrainerDynamaxMax = "Dynamax level 10"
                TrainerDynamaxRandom = "Random 0-10"
                ForceTrainerCanDynamax = "Allow every trainer Pokemon to Dynamax"
                ForceAllTeams = "Set every trainer to 6 Pokemon"
                ForceBossTeams = "Set selected bosses to 6 Pokemon"
                BossTeamsScope = "Boss list used for 6v6"
                AllowLegendaryTrainers = "Allow legendary Pokemon for trainers"
                TrainerExtraPokemon = "Extra Pokemon:"
                TrainerExtraBoss = "Boss"
                TrainerExtraImportant = "Important"
                TrainerExtraRegular = "Normal"
                TrainerSpecialRule = "Special rule:"
                TrainerSpecialRuleScope = "Special rule scope"
                TrainerLegendaryPolicy = "Legendary rule"
                TrainerMinBaseStatTotal = "Min. stats"
                RandomizeNatures = "Trainer natures"
                TypeMode = "Species types"
                ForceMonotype = "Force one type only"
                AbilityMode = "Global species abilities"
                AllowWonderGuard = "Allow Wonder Guard in the pool"
                StatMode = "Species base stats"
                ExpYieldMultiplier = "EXP yield multiplier"
                ForceOneExpYield = "No EXP mode: force 1 EXP from every Pokemon"
                MoveTypeMode = "Move type randomization"
                MovePowerMode = "Move power randomization"
                MovePPMode = "Move PP randomization"
                MovePowerMin = "Power min"
                MovePowerMax = "Power max"
                MovePPMin = "PP min"
                MovePPMax = "PP max"
                MoveAccuracyMode = "Move accuracy randomization"
                MoveAccuracyMin = "Accuracy min"
                MoveAccuracyMax = "Accuracy max"
                MoveCategoryMode = "Move physical/special split"
                EvolutionMode = "Evolution targets"
                AllowLegendaryEvo = "Allow legendary Pokemon in evolutions"
                NormalizeFriendship = "Convert friendship evolutions to a fixed level"
            FriendshipLevel = "Friendship level"
            NormalizeTrade = "Convert trade evolutions to a fixed level"
            TradeLevel = "Trade level"
            NormalizeSpecial = "Convert weird evolutions to a fixed level"
            SpecialLevel = "Special evo level"
                GiftMode = "Gift Pokemon mode"
                StarterMode = "Starter Pokemon mode"
                AllowLegendaryGifts = "Allow legendary Pokemon for gifts and starters"
                ManualStarterGroup = "Manual starters: leave the 3 boxes empty for the mode above, or fill all 3 to force a trio."
                Slot1 = "Slot 1"
                Slot2 = "Slot 2"
                Slot3 = "Slot 3"
                PatchStarters = "May be broken, do not use Patch early trainer teams tied to the starter choice"
                TradeMode = "In-game trades"
                AllowLegendaryTrades = "Allow legendary Pokemon in in-game trades"
                StaticMode = "Static / scripted encounters"
                AllowLegendaryStatic = "Allow legendary Pokemon in static encounters"
                StaticStableMapping = "Static stable mapping"
                GrassMode = "Wild encounter species"
                AllowLegendaryGrass = "Allow legendary Pokemon in grass / visible encounters"
                GrassStableMapping = "Wild encounter mapping rule"
                VisibleEncounterBehavior = "Visible Pokemon outside:"
                EncounterDrawMode = "Encounter draw mode"
                LiveVisibleMode = "Pokemon you SEE outside"
                LiveBattleMode = "Pokemon you FIGHT"
                AllowLegendaryLiveVisible = "Legendaries allowed outside"
                AllowLegendaryLiveBattle = "Legendaries allowed in battle"
                LiveGenerationFilter = "Allowed generations"
                OverworldVisiblePoolMode = "Species allowed outside"
                OverworldVisibleMaxHitbox = "Maximum bulk outside"
                UndergroundMode = "Underground encounters"
                AllowLegendaryUnderground = "Allow legendary Pokemon in underground"
                DisableExpShare = "Default EXP Share: OFF [REQUIRES EXEFS]"
                EarlyBike = "Rotom Bike from the start [REQUIRES EXEFS]"
                RuntimePcControls = "PC menu: change options in game [REQUIRES EXEFS]"
                DynamicExpLevelCap = "Dynamic EXP cap (ExLaunch) [REQUIRES EXEFS]"
                StrictBossMaxLevelCap = "Strict boss max level cap for listed bosses [REQUIRES EXEFS]"
                MainStorySoftLevelCap = "Soft main-story progression EXP cap [REQUIRES EXEFS]"
                GymLeagueStoryLevelCap = "Gym/Champion EXP cap [REQUIRES EXEFS]"
                StoryMajorBattleOrderLevelCap = "Ordered main-story major battle mode [REQUIRES EXEFS]"
                AutoInstallToEden = "Auto-install"
                EdenModName = "Mod folder"
                InstallTargetRyujinx = "Ryujinx"
                HelpBox = "Help"
                ResetTargets = "Reset targets"
                ResetButton = "Reset emulator install"
                ResetDefault = "This removes only the generated mod folder and the swsh-mods-exl config file when that config was generated by this randomizer."
                DetailsDefault = "Hover or focus any option to see exactly what it changes and where it is applied."
                StatusDefault = "Ready. Pick the user's ROMFS dump folder, add ExeFS only if a runtime/ExLaunch option needs it, choose your options, then generate the mod. The output includes ROMFS, ExLaunch files, config, and JSON reports when relevant."
                StatusRunning = "Building mod..."
                SeedError = "Seed must be a numeric integer. Use -1 for auto."
            }
            Descriptions = @{
                TrainerSpecies = "Trainer Pokemon: Completely random replaces each slot with any allowed Pokemon. Similar BST aims for comparable overall power using Base Stat Total. Do not change keeps vanilla species."
                TrainerMoves = "Trainer Pokemon moves: Random4 picks 4 attacks from the global move pool. Last 4 level-up moves uses the species' last 4 moves learned by level at the Pokemon's actual level."
                TrainerItems = "Items held by trainer Pokemon: Random only if present touches only slots that already had an item. Random item on everyone gives every trainer Pokemon one random held item. Remove all clears held items. Both random modes use the pool chosen on the right."
                TrainerItemPool = "Held item pool: Battle pool is curated for useful battle held items such as berries, Leftovers, Choice items, plates and type boosters. Wide safe pool is broader: it keeps key/problem items out, but can also roll balls, medicine, fossils, mints, candies and other safe non-key items for chaotic runs."
                TrainerAddedSlotSpecies = "Species for added slots: used only when a team is expanded to 6 while trainer species mode is Keep vanilla. Full random can add Empoleon to a Victreebel team; Similar BST tries comparable power; Same type keeps Gym/league themes such as Grass for Milo; Same type + BST keeps both. Leon/Tarak stays balanced."
                TrainerDuplicateMode = "Duplicate handling: Block duplicates is the current clean mode and repairs trainer teams so the same Pokemon or held item does not repeat. Normal random removes that repair; duplicates can happen naturally but are just random chance."
                TrainerAbility = "Trainer ability slot: randomizes the ability selector stored on each trainer Pokemon. It changes which normal/hidden ability slot is used, not the species' global ability data."
                TrainerIV = "IV mode: Max31 writes perfect IVs while preserving SWSH special flags. Random rolls each IV from 0 to 31 and also preserves shiny / CanDynamax flags."
                TrainerEV = "EV mode: Smogon strategic uses the EV spread from the selected Smogon set when available, then falls back to random legal EVs. Random legal distributes up to 510 EVs with the per-stat 252 cap. Zero removes EVs from every trainer Pokemon."
                TrainerLevel = "Level multiplier: multiplies trainer Pokemon levels and clamps the result to 1-100. Use 1.0 to leave levels untouched."
                TrainerTeamSize = "Team size: -1 means keep vanilla. Min / max clamp team size from 1 to 6. Force all teams to 6 overrides this by targeting 6 first, then the clamp still applies."
                TrainerTypeThemed = "Type-themed trainer teams: when trainer species are randomized, each trainer gets one random type and replacement Pokemon are pulled from that type's species pool. This is inspired by pkNX's TeamTypeThemed option."
                RandomizeNatures = "Trainer natures: Keep vanilla leaves each nature untouched, Random rolls one of the 25 legal natures, and Smogon strategic takes the nature from the same Smogon set as moves, item, ability and EVs."
                AllowLegendaryTrainers = "Allow legendary Pokemon for trainers: when disabled, legendary and mythical species are excluded from trainer replacement pools. This does not delete vanilla legendaries if species mode is unchanged."
                TrainerShinyChance = "Trainer shiny rate: 0 leaves trainer shininess untouched. Any value above 0 rolls that percentage on every trainer Pokemon and writes the verified SWSH shiny bit in trainer_poke."
                ForceTrainerFullyEvolved = "Force fully evolved after level: if a trainer Pokemon is at least this level, the tool follows its evolution chain and replaces it with a final-stage evolution. Branching evolutions pick one allowed branch."
                MaxTrainerAI = "Maximize trainer AI: sets the trainer AI flag field to all enabled flags. This is based on pkNX's TrainerMaxAI option and makes battles less passive."
                TrainerDynamaxLevel = "Trainer Dynamax level: changes the Dynamax level byte in each trainer Pokemon record. Max10 makes Dynamax HP boost strongest; Random0-10 varies it."
                ForceTrainerCanDynamax = "Allow every trainer Pokemon to Dynamax: sets the verified SWSH CanDynamax bit in trainer_poke. This does not force Gigantamax forms."
                ForceAllTeams = "Force all trainer teams to 6 Pokemon: expands every trainer party up to six slots by cloning a random existing slot to keep a coherent level/template. Added slots are then re-leveled toward the team's real level range and still go through the normal trainer options afterward: species mode, trainer move mode, held item mode, IV/EV mode, shiny rate, Dynamax settings, and so on. When trainer species randomization is active, duplicate species inside the final team are now blocked: uniqueness takes priority, and if the current mode pool runs out the randomizer broadens the candidate pool instead of accepting duplicates."
                ForceBossTeams = "Listed champion / league / major boss teams to 6 Pokemon: expands only the important fights detected from vanilla trainer metadata. Added slots no longer duplicate only the last Pokemon: each extra slot takes a random existing slot as level template, is re-leveled toward the real team range, then still follows the usual trainer options afterward, including species mode and trainer move mode. When trainer species randomization is active, duplicate species inside the final team are now blocked: uniqueness takes priority, and if the current mode pool runs out the randomizer broadens the candidate pool instead of accepting duplicates. The very first Hop starter-choice battle is intentionally excluded so that opening fight keeps its special 2-Pokemon structure. The visible list shows unique characters; randomizer-report.json and trainer-changes.json export the exact trainer IDs and before/after team sizes."
                BossTeamsScope = "Boss 6v6 scope: Major bosses is the broad mode and can include rivals plus story/DLC bosses such as Hop, Bede, Marnie, Leon, Rose, Oleana, Sordward, Shielbert, Mustard, Klara, Avery and Peony. Gyms + league only is narrower: it targets Gym Leaders, Champion Cup / league-style entries and Leon, so the 6-Pokemon helper behaves more like a classic Gyms + Elite Four style run."
                ForceBossTargets = "Boss target list: includes rivals and story bosses such as Hop, Bede, Marnie, Leon, Rose, Oleana, Sordward, Shielbert, DLC bosses such as Mustard, Klara, Avery, Peony, Peonia, plus Gym Leader / Champion Cup / league fights detected in vanilla data. The very first Hop starter-choice battle is intentionally excluded from the 6-Pokemon helper. Generic Macro Cosmos employees are intentionally not included."
                TypeMode = "Pokemon types: Random changes types for all species. With monotype enabled, type 2 is copied from type 1."
                TypesMonotypeOnly = "Force monotype: when Pokemon types are randomized, the second type is forced to match the first type instead of rolling a dual type."
                AbilityMode = "Pokemon abilities: randomizes species ability slots in personal data. Wonder Guard is blocked unless explicitly allowed."
                AllowWonderGuard = "Allow Wonder Guard: includes Wonder Guard in the ability pool. This can create very strong or unfair Pokemon, so it is opt-in."
                StatMode = "Base stats: Shuffle permutes the 6 stats. Redistribute keeps the same BST total but builds a different spread."
                ExpYieldMultiplier = "EXP yield multiplier: when different from 1.0, the generated ExLaunch config applies it to the final EXP gain at runtime instead of editing personal_total.bin. 0.6 matches the idea of the 60_sw mod, and 5.0 makes a true x5 multiplier. No EXP mode overrides this value."
                ForceOneExpYield = "No EXP mode: forces every Pokemon species that normally gives EXP to yield 1 EXP. This is the clean ROMFS version of the local no_exp_v132_ mod. It is global and static. Use Dynamic EXP level cap if you want the game to check the receiver Pokemon's level during battle."
                MoveTypeMode = "Move types: changes the elemental type of global moves. Example: Fire Fang can become Ice-type."
                MovePowerMode = "Move power: randomizes damaging move power only. Moves with base power 0 are left at 0 to avoid turning pure status moves into broken attacks."
                MovePPMode = "Move PP: randomizes base PP for global moves inside the selected range."
                MoveAccuracyMode = "Move accuracy: randomizes accuracy for moves that normally use an accuracy value. Perfect / special-case accuracy 0 is preserved."
                MoveCategoryMode = "Move category: randomizes damaging moves between physical and special. Status moves are preserved."
                StarterMode = "Starter Pokemon mode: Random starter Pokemon replaces only the three starter species. Similar BST keeps them close to Grookey / Scorbunny / Sobble power. This global mode is used only when all three manual starter boxes are left empty."
                Starter1 = "Manual starter slot 1. You can type a French or English species name, for example Pikachu, Bulbizarre or Eevee. If you force manual starters, all 3 boxes must be filled."
                Starter2 = "Manual starter slot 2. Leave the 3 boxes empty to keep using the starter mode above. Fill the 3 boxes to force an exact visible trio."
                Starter3 = "Manual starter slot 3. The JSON report exports the chosen trio with both French and English names."
                PatchStarters = "Patch trainer teams tied to the starter choice: after changing the three visible starters, the script reads vanilla trainer metadata, finds every Grookey / Scorbunny / Sobble family slot, and forces those exact slots to the final starter trio. This still works if trainer Pokemon were randomized first, and the patched slots now rebuild their moves so they stop keeping the previous species move set."
                ReportLanguage = "JSON report language: chooses the primary language for exported labels. Species name input still accepts French and English."
                UiLanguage = "Software language: instantly switches the interface text and help descriptions between French and English."
                EvolutionMode = "Pokemon Evolution: Completely random remaps evolution targets freely. Similar BST prefers targets with comparable power."
                AllowLegendaryEvo = "Allow legendary Pokemon in evolutions: includes legendary and mythical species in randomized evolution targets. Leave it off for a more regular progression."
                NormalizeFriendship = "Friendship normalization converts friendship methods into plain level-up evolution. Covered methods: 1, 2, 3."
                NormalizeTrade = "Trade normalization converts plain trade, trade-with-item, and trade-for-specific-Pokemon methods into plain level-up evolution. Covered methods: 5, 6, 7."
                NormalizeSpecial = "Weird evolution normalization converts every non-empty evolution method that is not already plain level-up into a fixed level-up evolution. This covers time, beauty, location, item/stone, move-known, gender/weather/party requirements and other special conditions. If you want to keep item or stone evolutions, leave this unchecked."
                GiftMode = "Gift Pokemon mode: edits non-starter gift Pokemon from add_poke.bin. Completely random ignores power; Similar BST keeps gifts closer to their original strength."
                AllowLegendaryGifts = "Allow legendary Pokemon for gifts and starters: includes legendary and mythical species in gift and starter replacement pools."
                TradeMode = "In-game trades: edits NPC trade species. Both the requested Pokemon and the received Pokemon can be randomized where the file exposes them."
                AllowLegendaryTrades = "Allow legendary Pokemon in in-game trades: includes legendary and mythical species in NPC trade replacement pools."
                StaticMode = "Static / scripted encounters: edits fixed in-world encounters from event_encount_data.bin."
                AllowLegendaryStatic = "Allow legendary Pokemon in static encounters: includes legendary and mythical species in fixed/scripted encounter replacement pools."
                GrassMode = "Wild encounter species: controls the ROMFS encounter tables used by grass, symbols and field encounters. Keep vanilla leaves the species tables untouched; the option below can still add a runtime split between what is seen outside and what starts in battle."
                AllowLegendaryGrass = "Allow legendary Pokemon in grass / visible encounters: includes legendary and mythical species in hidden grass and visible overworld replacement pools."
                StaticStableMapping = "Static mapping: Species maps every same vanilla species to the same replacement. Slot draws each static/script table entry independently. Neither rerolls encounters live in-game."
                GrassStableMapping = "Wild encounter mapping rule: Stable by species means every vanilla Pikachu of a zone becomes the same replacement. Stable by slot draws each table entry on its own, so Route 4 Pikachu and another area Pikachu can become different species."
                VisibleEncounterBehavior = "Overworld Pokemon behavior: Fixed mask never rewrites the overworld model and only changes the battle copy. Permanent reveal stores the first hidden result for that zone/source, then shows and fights that same result. Classic disables the runtime hidden battle layer."
                EncounterDrawMode = "Encounter draw mode: Slot by species maps each source species/form in a zone to a stable result. Full random rerolls visible ROMFS entries and battle results independently. Fixed visible + random battle keeps ROMFS sprites and rerolls only the battle."
                LiveVisibleMode = "Pokemon you SEE outside [REQUIRES EXEFS]: Unchanged / Random every spawn / Stable per zone / Stable everywhere / Zone discovery."
                LiveBattleMode = "Pokemon you FIGHT [REQUIRES EXEFS]: set it differently from the visible mode to get the hidden battle."
                LiveGenerationFilter = "Generations allowed in the runtime draw, comma separated. Example: 1,2,3"
                UndergroundMode = "Underground encounters: edits the underground encounter species slots stored separately from normal field encounters."
                AllowLegendaryUnderground = "Allow legendary Pokemon in underground: includes legendary and mythical species in underground encounter replacement pools."
                DisableExpShare = "Default EXP Share: OFF: writes enabled=false to the generated ExLaunch [exp_share] config. If the PC runtime menu is enabled, this is only the starting state and the player can toggle it in game."
                EarlyBike = "Rotom Bike from the start: writes active=true to the generated ExLaunch [early_bike] config. The module grants the real Rotom Bike key item once the field is loaded."
                RuntimePcControls = "PC menu runtime controls: opt-in replacement of the Pokemon Center PC script. This option does not disable EXP Share by itself; it only allows changing runtime options in game. When unchecked, the vanilla PC menu stays intact and the generated config defaults are used directly."
                DynamicExpLevelCap = "Dynamic EXP level cap: no longer writes the old raw IPS. The reliable path uses ExLaunch at the final EXP calculation point. The tool deploys the project's ExLaunch-compatible main.npdm together with the custom subsdk9 module."
                StrictBossMaxLevelCap = "Strict boss max level cap: still computes and normalizes the listed boss teams, but in-game EXP enforcement now requires the ExLaunch module. The tool deploys the project's ExLaunch-compatible main.npdm together with the custom subsdk9 module. Without that module, the JSON is a reference and EXP is not blocked."
                MainStorySoftLevelCap = "Soft main-story progression EXP cap: each step takes the highest level among the major fights of the same badge window. MEASURED 2026-09-07: across Sword's 50 major battles the gym leader is the strongest fight of its window every time - rivals sit 1 to 4 levels below. This option therefore yields EXACTLY the same 9 steps as the gym/champion cap, and the generator says so. Kept for existing scripts; details are still exported to story-main-progression-soft-caps.json."
                GymLeagueStoryLevelCap = "Gym/champion story EXP cap: computes a 9-step cap table from generated gym/champion teams. In-game enforcement requires ExLaunch. The tool deploys the project's ExLaunch-compatible main.npdm together with the custom subsdk9 module."
                StoryMajorBattleOrderLevelCap = "Ordered main-story major battle mode: keeps the dynamic EXP patch globally, then normalizes a fixed ordered list of major base-story fights to each team's max level after randomization. It covers the gyms plus major Hop, Bede, Marnie, Oleana, Rose, and Leon battles from the main story, exports them to story-major-battle-caps.json, and uses every starter-dependent or version-dependent variant that exists in trainer data. This is still based on a curated ordered list, not a live hidden story-state reader."
                AutoInstallToEden = "Auto-install into selected detected emulators: after generation finishes, the tool tries to copy romfs, exefs and the generated sdmc subtree into every checked emulator found on the PC."
                EdenModName = "Installed mod folder name: controls the final mod folder name under the emulator-specific load/mods path. Keep Randomizer if you simply want the new build to replace the previous run."
                InstallTargetRyujinx = "Install to Ryujinx: this target uses %AppData%\\Ryujinx\\mods\\contents\\<titleId>\\<modName> plus %AppData%\\Ryujinx\\sdcard\\config\\swsh-mods-exl\\config.toml. Legacy sdcard\\atmosphere\\contents installs are cleaned automatically."
                ValidateBuild = "Build validation: checks source folders, required ROMFS files, ExeFS needs for runtime options, numeric ranges and obvious option conflicts before generation. Example: if hidden visible battles are enabled without an ExeFS dump, the build is blocked before writing a broken mod."
                BuildSummary = "Build summary: opens the same 'what will be modified' page used before generation. Example: before writing files, it shows whether trainers, encounters, EXP Share, ExLaunch, Smogon options and emulator install targets will be changed."
            }
        }
    }

    return @{
        FormTitle = "PokeFeur Randomizer SWSH $AppVersion"
            SourceLabel = "Dossier ROMFS original"
            SourceExefsLabel = "Dossier ExeFS original"
            OutputLabel = "Dossier du mod généré"
            GameVersion = "Jeu cible"
        Browse = "Parcourir"
        Seed = "Seed (-1 = auto)"
        UiLanguage = "Langue du logiciel"
        ReportLanguage = "Langue rapport JSON"
        Theme = "Thème"
        ValidateBuild = "Vérifier config"
        BuildSummary = "Résumé build"
        Generate = "Générer le mod"
        Tabs = @{ General = "Génération"; Trainers = "Dresseurs"; Pokemon = "Pokémon"; Evolutions = "Évolutions"; Gifts = "Starters / cadeaux"; Encounters = "Rencontres"; Comfort = "Confort / divers"; Help = "Aide"; Reset = "Nettoyage" }
        GeneralLines = @(
            "Build complet: ROMFS utilisateur + ExeFS utilisateur, ExLaunch, presets JSON, rapports détaillés et installation auto émulateurs.",
            "BST = somme des 6 stats de base. Le mode BST proche garde une puissance comparable.",
            "Dresseurs: espèces, moves, objets, IV/EV, shiny, IA, Dynamax, tailles d'équipe et boss a 6.",
            "Pokémon: types, talents, stats, EXP donnée, attaques globales et évolutions.",
            "Rencontres: fixes, sauvages, visibles, underground, mappings stables et combats cachés.",
            "Starters: noms FR/EN acceptés, exemple Empiflor / Pingoleon / Empiflor.",
            "Caps EXP: les modes runtime demandent ExLaunch et exportent leurs tables JSON."
        )
            ModeRandom = "Random complet"
            ModeSimilarBST = "Random equilibre (BST proche)"
            ModeUnchanged = "Garder vanilla"
            MappingSlot = "Stable par slot"
            MappingSpecies = "Stable par espèce"
            ModeVanillaGame = "Inchangé (celui du jeu)"
            DrawRandom = "Tirage aléatoire"
            BagEmpty = "Sac vide (aucun soin)"
            BagRandom = "Objets tirés au hasard"
            ScopeOff = "Désactivé"
            ScopeGymLeague = "Arènes + Ligue"
            ScopeAllBosses = "Tous les boss"
            ScopeEveryone = "Tout le monde"
            LegendaryPolicyUnchanged = "Ne rien imposer"
            LegendaryPolicyNone = "Aucun légendaire"
            LegendaryPolicyOneEach = "Un légendaire chacun"
            LegendaryPolicyAll = "Que des légendaires"
            LearnsetShuffle = "Permuter entre espèces"
            LearnsetFullRandom = "Tirage intégral (toutes les attaques)"
            ShopItemSamePocket = "Même genre d'objet"
            ShopItemFullRandom = "Tout ce que la boutique vend"
            ShopPriceFree = "Gratuit (x0)"
            ShopPriceHalf = "Moitié prix (x0.5)"
            ShopPriceNormal = "Prix normaux (x1)"
            ShopPriceDouble = "Double (x2)"
            ShopPriceExpensive = "Très cher (x5)"
            ShopPriceRandomSmall = "Aléatoire (100 - 5 000)"
            ShopPriceRandomMedium = "Aléatoire (300 - 20 000)"
            ShopPriceRandomWide = "Aléatoire (1 - 999 999)"
            FieldPoolSafe = "Sans objets clés"
            FieldPoolAll = "Tout, CT et DT incluses"
            NpcGiftShuffle = "Permuter entre PNJ"
            LiveRandomSpawn = "Aléatoire à chaque apparition"
            LiveRandomBattle = "Aléatoire à chaque combat"
            LiveStableZone = "Stable par zone"
            LiveStableGlobal = "Stable partout"
            LiveDiscovery = "Découverte de zones"
            LiveDiscoveryRandom = "Découverte, herbe aléatoire"
            OverworldPoolVanilla = "Visibles en vanilla (les 330 de base)"
            OverworldPoolAll = "Toutes les espèces"
            OverworldPoolUnusual = "TEST : uniquement les non prévues"
            HitboxNone = "Aucune limite"
            HitboxColossal = "Sans les colosses"
            HitboxVeryLarge = "Sans les très gros"
            HitboxLarge = "Sans les gros"
            HitboxCompact = "Compact"
            ExpCurveFast = "Tous rapides"
            ExpCurveMedium = "Tous moyens"
            ExpCurveSlow = "Tous lents"
            TmShuffle = "Permuter entre machines"
            CompatHalf = "Une chance sur deux"
            CompatSameType = "Préférer le même type"
            CompatFull = "Tout apprendre"
        TrainerMoveRandom4 = "4 attaques aléatoires"
        TrainerMoveLevel4 = "Attaques naturelles au niveau"
        TrainerMoveSmogon = "Stratégique Smogon"
        TrainerMoveSmogonLegacy = "Smogon + anciennes gens"
        TrainerSmogonMoveFallbackLevel = "Secours : attaques naturelles"
        TrainerSmogonMoveFallbackRandom = "Secours : attaques aléatoires"
        TrainerSmogonMoveFallbackUnchanged = "Backup: garder vanilla"
        TrainerItemRandomPresent = "Random si objet déjà présent"
        TrainerItemForceAll = "Objet random sur tous"
        TrainerItemSmogon = "Objet stratégique Smogon"
        TrainerItemSmogonLegacy = "Objet Smogon + anciennes gens"
        TrainerItemRemoveAll = "Supprimer tous les objets"
        TrainerItemPoolBattle = "Pool combat (objets utiles)"
        TrainerItemPoolFull = "Pool large safe (chaotique)"
        TrainerAddedSlotRandom = "Ajouts : aléatoire complet"
        TrainerAddedSlotSimilarBST = "Ajouts : BST proche"
        TrainerAddedSlotSameType = "Ajouts : même type"
        TrainerAddedSlotSameTypeBST = "Ajouts : même type + BST"
        TrainerDuplicateNoDuplicates = "Bloquer les doublons"
        TrainerDuplicateNormal = "Random normal (doublons possibles)"
        BossScopeMajor = "Boss importants"
        BossScopeGymLeague = "Arènes + ligue uniquement"
        TrainerAbilityRandom = "Randomiser le slot talent dresseur"
        TrainerAbilitySmogon = "Talent stratégique Smogon"
        TrainerAbilitySmogonLegacy = "Talent Smogon + anciennes gens"
        TrainerIVMax = "31 partout"
        TrainerIVRandom = "Aléatoire"
        TrainerEVSmogon = "EV strategiques Smogon"
        TrainerEVSmogonLegacy = "EV Smogon + anciennes gens"
        TrainerEVRandom = "EV legaux aléatoires"
        TrainerEVZero = "Mettre les EV à zéro"
        TrainerNatureUnchanged = "Garder nature vanilla"
        TrainerNatureRandom = "Nature aléatoire"
        TrainerNatureSmogon = "Nature stratégique Smogon"
        TrainerNatureSmogonLegacy = "Nature Smogon + anciennes gens"
        StarterRandom = "Starters aléatoires"
        StarterSimilarBST = "Starters BST proche"
        StarterUnchanged = "Ne pas changer les starters"
        StatShuffle = "Melanger les 6 stats"
        StatRedistribute = "Redistribuer le BST"
        ReportLanguageFrench = "Français"
        ReportLanguageEnglish = "English"
        UiLanguageFrench = "Français"
        UiLanguageEnglish = "English"
        ThemeLight = "Clair"
        ThemeDark = "Sombre"
        Labels = @{
            TrainerSpecies = "Pokémon des dresseurs"
            TrainerMoves = "Attaques des dresseurs"
            TrainerSmogonMoveFallback = "Attaques de secours Smogon"
            TrainerItems = "Objets tenus des dresseurs"
            TrainerItemPool = "Pool des objets random"
            TrainerAddedSlotSpecies = "Pokémon ajoutés aux équipes a 6"
            TrainerDuplicateMode = "Doublons dans les équipes"
            TrainerAbility = "Talents des dresseurs"
            TrainerIV = "IV des dresseurs"
            TrainerEV = "EV des dresseurs"
            TrainerLevel = "Multiplicateur des niveaux"
            TrainerTeamMin = "Équipe mini"
            TrainerTeamMax = "Équipe maxi"
            TrainerTypeThemed = "Équipes random par type"
            TrainerShinyChance = "Taux shiny dresseurs (%)"
            ForceTrainerFullyEvolved = "Forcer les évolutions finales"
            TrainerFullyEvolvedLevel = "Niveau minimum évolution finale"
            MaxTrainerAI = "IA dresseur au maximum"
            TrainerDynamaxLevel = "Niveau Dynamax dresseurs"
            TrainerDynamaxUnchanged = "Ne pas changer"
            TrainerDynamaxMax = "Dynamax niveau 10"
            TrainerDynamaxRandom = "Aléatoire 0-10"
            ForceTrainerCanDynamax = "Autoriser Dynamax chez tous les dresseurs"
            ForceAllTeams = "Mettre tous les dresseurs à 6 Pokémon"
            ForceBossTeams = "Mettre certains boss à 6 Pokémon"
            BossTeamsScope = "Liste de boss utilisée"
            AllowLegendaryTrainers = "Autoriser les légendaires chez les dresseurs"
            TrainerExtraPokemon = "Pokémon en plus :"
            TrainerExtraBoss = "Boss"
            TrainerExtraImportant = "Important"
            TrainerExtraRegular = "Normal"
            TrainerSpecialRule = "Règle spéciale :"
            TrainerSpecialRuleScope = "Portee de la règle"
            TrainerLegendaryPolicy = "Règle légendaires"
            TrainerMinBaseStatTotal = "Stats mini"
            RandomizeNatures = "Natures des dresseurs"
            TypeMode = "Types des espèces"
            ForceMonotype = "Forcer un seul type"
            AbilityMode = "Talents globaux des espèces"
            AllowWonderGuard = "Autoriser Wonder Guard dans le pool"
            StatMode = "Stats de base des espèces"
            ExpYieldMultiplier = "Multiplicateur d'EXP donnée"
            ForceOneExpYield = "Mode No EXP: forcer 1 EXP par Pokémon battu"
            MoveTypeMode = "Randomiser les types d'attaques"
            MovePowerMode = "Randomiser la puissance"
            MovePPMode = "Randomiser les PP"
            MovePowerMin = "Puissance min"
            MovePowerMax = "Puissance max"
            MovePPMin = "PP min"
            MovePPMax = "PP max"
            MoveAccuracyMode = "Randomiser la précision"
            MoveAccuracyMin = "Précision min"
            MoveAccuracyMax = "Précision max"
            MoveCategoryMode = "Randomiser physique/spécial"
            EvolutionMode = "Cibles d'évolution"
            AllowLegendaryEvo = "Autoriser légendaires en évolution"
            NormalizeFriendship = "Convertir les évolutions amitie en niveau fixe"
            FriendshipLevel = "Niveau amitie"
            NormalizeTrade = "Convertir les évolutions échange en niveau fixe"
            TradeLevel = "Niveau échange"
            NormalizeSpecial = "Convertir les évolutions chelou en niveau fixe"
            SpecialLevel = "Niveau spécial"
            GiftMode = "Pokémon cadeaux"
            StarterMode = "Starters"
            AllowLegendaryGifts = "Autoriser les légendaires pour gifts et starters"
            ManualStarterGroup = "Starters manuels: laisse les 3 champs vides pour le mode ci-dessus, ou remplis les 3 pour forcer un trio."
            Slot1 = "Slot 1"
            Slot2 = "Slot 2"
            Slot3 = "Slot 3"
            PatchStarters = "Repatcher les équipes liees au choix du starter"
            TradeMode = "Trades PNJ"
            AllowLegendaryTrades = "Autoriser légendaires dans les trades PNJ"
            StaticMode = "Rencontres fixes / scriptes"
            AllowLegendaryStatic = "Autoriser légendaires en rencontres fixes"
            StaticStableMapping = "Mapping stable statiques"
            GrassMode = "Espèces des rencontres sauvages"
            AllowLegendaryGrass = "Autoriser légendaires en herbes / visibles"
            GrassStableMapping = "Règle de mapping sauvage"
            VisibleEncounterBehavior = "Pokémon visibles dehors :"
            EncounterDrawMode = "Mode de tirage rencontres"
            LiveVisibleMode = "Pokémon que tu VOIS dehors"
            LiveBattleMode = "Pokémon que tu AFFRONTES"
            AllowLegendaryLiveVisible = "Légendaires autorises dehors"
            AllowLegendaryLiveBattle = "Légendaires autorises en combat"
            LiveGenerationFilter = "Générations autorisees"
            OverworldVisiblePoolMode = "Espèces autorisées dehors"
            OverworldVisibleMaxHitbox = "Encombrement maximal dehors"
            UndergroundMode = "Underground / chika"
            AllowLegendaryUnderground = "Autoriser légendaires en underground"
            DisableExpShare = "EXP Share par défaut: OFF [NÉCESSITE EXEFS]"
            EarlyBike = "Velo Rotom des le début [NÉCESSITE EXEFS]"
            RuntimePcControls = "Menu PC: changer en jeu [NÉCESSITE EXEFS]"
            DynamicExpLevelCap = "Cap EXP dynamique (ExLaunch) [NÉCESSITE EXEFS]"
            StrictBossMaxLevelCap = "Cap boss max strict pour les boss listes [NÉCESSITE EXEFS]"
            MainStorySoftLevelCap = "Cap progression principale (souple) [NÉCESSITE EXEFS]"
            GymLeagueStoryLevelCap = "Cap EXP arènes/Tarak [NÉCESSITE EXEFS]"
            StoryMajorBattleOrderLevelCap = "Mode ordre histoire principale (boss majeurs) [NÉCESSITE EXEFS]"
            AutoInstallToEden = "Installation auto"
            EdenModName = "Dossier du mod"
            InstallTargetRyujinx = "Ryujinx"
            HelpBox = "Aide"
            ResetTargets = "Cibles du reset"
            ResetButton = "Reset de l'installation émulateur"
            ResetDefault = "Le reset supprime seulement le dossier de mod généré et le fichier swsh-mods-exl quand cette config a été générée par ce randomizer."
            DetailsDefault = "Survole ou sélectionne une option pour voir exactement ce qu'elle modifie et ou c'est applique."
            StatusDefault = "Prêt. Choisis le dossier ROMFS de ton dump, ajoute ExeFS seulement si une option runtime/ExLaunch en a besoin, règle tes options, puis génère le mod. La sortie contient ROMFS, fichiers ExLaunch, config et rapports JSON si nécessaire."
            StatusRunning = "Génération en cours..."
            SeedError = "Le seed doit être un entier numérique. Utilise -1 pour auto."
        }
        Descriptions = @{
            TrainerSpecies = "Pokémon des dresseurs: Random complet remplace chaque slot par n'importe quel Pokémon autorise. Random equilibre (BST proche) vise une puissance globale proche. Garder vanilla conserve les espèces d'origine."
            TrainerMoves = "Attaques des dresseurs: 4 attaques aléatoires pioche dans le pool global. Attaques naturelles au niveau reconstruit les attaques apprises normalement par le Pokémon a son niveau."
            TrainerItems = "Objets tenus dresseurs: Random seulement si présent respecte les slots qui ont déjà un objet. Objet random sur tous donne un objet tenu aléatoire a chaque Pokémon de dresseur. Supprimer tous les objets vide les objets. Les deux modes random utilisent le pool choisi a droite."
            TrainerItemPool = "Pool d'objets tenus: Combat pioche surtout dans les objets utiles en combat comme baies, Restes, Choice items, plaques et boosts de type. Pool large safe est plus large: il evite les objets clés/problèmes, mais peut aussi tirer balls, soins, fossiles, mints, bonbons et autres objets non-clé pour les runs chaotiques."
            TrainerAddedSlotSpecies = "Espèces des slots ajoutés: utilise seulement quand une équipe passe a 6 alors que le mode Pokémon dresseurs est Garder vanilla. Random complet peut ajouter Pingoleon dans une équipe Empiflor; BST proche cherche une puissance comparable; Même type garde le thème arène/ligue comme Plante pour Milo; Même type + BST garde thème et puissance. Tarak reste equilibre."
            TrainerDuplicateMode = "Gestion des doublons: Bloquer les doublons est le mode propre actuel et repare les équipes pour éviter deux fois le même Pokémon ou le même objet tenu. Random normal retire cette reparation: un doublon peut arriver naturellement, mais seulement par hasard."
            TrainerAbility = "Slot talent dresseur: randomise le selecteur de talent stocke sur chaque Pokémon de dresseur. Ca change le slot utilise, pas les talents globaux de l'espèce."
            TrainerIV = "Mode IV: 31 partout écrit des IV parfaits tout en preservant les flags spéciaux SWSH. Aléatoire lance chaque IV entre 0 et 31 et preserve aussi shiny / CanDynamax."
            TrainerEV = "Mode EV: Stratégique Smogon utilise la répartition EV du set Smogon choisi quand elle existe, puis retombe sur EV legaux aléatoires. EV legaux aléatoires distribue jusqu'a 510 EV avec la limite 252 par stat. Zéro retire les EV de tous les Pokémon de dresseurs."
            TrainerLevel = "Multiplicateur niveau: multiplie les niveaux des Pokémon de dresseurs et limite le résultat entre 1 et 100. Mets 1.0 pour ne pas toucher aux niveaux."
            TrainerTeamSize = "Taille équipe: -1 garde la valeur vanilla. Min / max limite la taille entre 1 et 6. Forcer toutes les équipes a 6 vise d'abord 6, puis la limite min/max s'applique."
            TrainerTypeThemed = "Équipes themees par type: quand les espèces des dresseurs sont randomisées, chaque dresseur tire un type et les remplacements viennent du pool de ce type. Inspire de l'option TeamTypeThemed de pkNX."
            RandomizeNatures = "Natures dresseurs: Garder vanilla ne touche pas aux natures, Nature aléatoire tire une des 25 natures legales, et Nature stratégique Smogon prend la nature du même set Smogon que les attaques, l'objet, le talent et les EV."
            AllowLegendaryTrainers = "Légendaires chez les dresseurs: si cette option est decochee, les légendaires et mythiques sont exclus des pools de remplacement. Ca ne supprime pas les légendaires vanilla si le mode Pokémon reste Ne pas changer."
            TrainerShinyChance = "Taux shiny dresseurs: 0 ne touche pas au shiny. Une valeur au-dessus de 0 lance ce pourcentage sur chaque Pokémon de dresseur et écrit le bit shiny SWSH vérifie dans trainer_poke."
            ForceTrainerFullyEvolved = "Forcer stade final après niveau: si un Pokémon de dresseur atteint au moins ce niveau, l'outil suit sa chaîne d'évolution et le remplace par une évolution finale. Les évolutions a branches choisissent une branche autorisee."
            MaxTrainerAI = "IA dresseur au maximum: active tous les flags d'IA connus dans trainer_data, comme l'option TrainerMaxAI de pkNX. Les combats deviennent moins passifs."
            TrainerDynamaxLevel = "Niveau Dynamax dresseurs: modifie l'octet de niveau Dynamax de chaque Pokémon de dresseur. Niveau 10 maximise le bonus de PV Dynamax; aléatoire 0-10 varié selon les slots."
            ForceTrainerCanDynamax = "Autoriser tous les Pokémon de dresseurs a Dynamax: active le bit CanDynamax vérifie dans trainer_poke. Ne force pas les formes Gigamax."
            ForceAllTeams = "Forcer toutes les équipes a 6 Pokémon: etend chaque équipe de dresseur jusqu'a six slots en clonant d'abord un slot existant choisi au hasard pour garder un modèle cohérent. Les slots ajoutés sont ensuite recales vers la vraie plage de niveaux de l'équipe, puis ils repassent dans les options normales du bloc dresseurs: mode espèce, mode moves, objets tenus, IV/EV, shiny, Dynamax, etc. Si la randomisation des espèces dresseurs est active, les doublons d'espèce dans l'équipe finale sont maintenant bloques: l'unicite passe en priorité, et si le pool du mode courant est trop petit le randomizer elargit la sélection au lieu d'accepter un doublon."
            ForceBossTeams = "Boss listes ci-contre a 6 Pokemon: etend seulement les combats importants detectes depuis les donnees dresseurs vanilla. Les slots ajoutes ne recopient plus juste le dernier Pokemon: chaque slot bonus prend un slot existant au hasard comme modele de niveau, est recale vers la vraie plage de niveaux de l'equipe, puis suit quand meme les options normales ensuite, y compris le mode espece et le mode moves dresseurs. Si la randomisation des especes dresseurs est active, les doublons d'espece dans l'equipe finale sont maintenant bloques: l'unicite passe en priorite, et si le pool du mode courant est trop petit le randomizer elargit la selection au lieu d'accepter un doublon. Le tout premier combat de Nabil au choix du starter est volontairement exclu pour garder sa structure speciale a 2 Pokemon. La liste visible affiche les personnages uniques; randomizer-report.json et trainer-changes.json exportent les IDs exacts des combats et les tailles d'equipe avant/apres."
            BossTeamsScope = "Liste de boss utilisee pour les équipes a 6: Boss importants est le mode large et peut inclure rivaux, boss histoire et DLC comme Nabil, Travis, Rosemary, Tarak, Shehroz, Liv, Jean-Fleuret, Jean-Targe, Mustar, Sophora, Saturnin et Dhilan. Arènes + ligue uniquement est plus strict: il cible champions d'arène, entrées type Champion Cup / ligue et Tarak, pour une run plus proche du style arènes + conseil 4."
            ForceBossTargets = "Liste des cibles boss: inclut les rivaux et boss d'histoire comme Nabil, Travis, Rosemary, Tarak, Shehroz, Liv, Jean-Fleuret, Jean-Targe, les boss DLC comme Mustar, Sophora, Saturnin, Dhilan, Pivonia, plus les champions d'arène / Champion Cup / ligue detectes dans les données vanilla. Le tout premier combat de Nabil au choix du starter est volontairement exclu de l'aide 6 Pokémon. Les employes Macro Cosmos generiques ne sont volontairement pas inclus."
            TypeMode = "Types: Random change les types de toutes les espèces. Si monotype est coche, le type 2 recopie le type 1."
            TypesMonotypeOnly = "Forcer monotype: quand les types Pokémon sont randomises, le type 2 recopie le type 1 au lieu de tirer un double type."
            AbilityMode = "Talents Pokémon: randomise les slots de talents dans les données personal. Wonder Guard est bloque sauf si tu l'autorises explicitement."
            AllowWonderGuard = "Autoriser Wonder Guard: ajoute Wonder Guard au pool de talents. Ca peut créer des Pokémon très forts ou injustes, donc c'est volontairement séparé."
            StatMode = "Stats: Shuffle permute les 6 stats entre elles. Redistribute conserve le BST total mais recompose une répartition différente."
            ExpYieldMultiplier = "Multiplicateur EXP donne: quand il est different de 1.0, la config ExLaunch generee l'applique au gain EXP final en jeu au lieu de modifier personal_total.bin. 0.6 reproduit l'idee du mod 60_sw, 5.0 fait un vrai x5. Le mode No EXP prend le dessus sur cette valeur."
            ForceOneExpYield = "Mode No EXP: force toutes les espèces qui donnent normalement de l'EXP a donner exactement 1 EXP. C'est la version ROMFS propre du mod local no_exp_v132_. C'est global et statique. Utilise le levelcap EXP dynamique si tu veux que le jeu vérifie le niveau du Pokémon receveur pendant le combat."
            MoveTypeMode = "Types des attaques: change le type elementaire des attaques globales. Exemple: Crocs Feu peut devenir de type Glace."
            MovePowerMode = "Puissance attaques: randomise seulement la puissance des attaques offensives. Les attaques a puissance 0 restent a 0 pour éviter de casser les attaques de statut."
            MovePPMode = "PP attaques: randomise les PP de base des attaques globales dans la plage choisie."
            MoveAccuracyMode = "Précision des attaques : randomise la précision des attaques qui en utilisent une. Les cas spéciaux à 0 restent à 0."
            MoveCategoryMode = "Catégorie attaques: randomise les attaques offensives entre physique et spécial. Les attaques de statut sont conservées."
            StarterMode = "Mode starters: Starters aléatoires remplace uniquement les trois starters. Starters BST proche garde une puissance proche de Ouistempo / Flambino / Larmeleon. Ce mode global n'est utilise que si les 3 champs de starters manuels restent vides."
            Starter1 = "Starter manuel slot 1. Tu peux taper un nom FR ou EN, par exemple Pikachu, Bulbizarre ou Eevee. Si tu forces des starters manuels, les 3 champs doivent être remplis."
            Starter2 = "Starter manuel slot 2. Laisse les 3 champs vides pour continuer a utiliser le mode starters ci-dessus. Renseigne les 3 champs pour imposer exactement le trio visible."
            Starter3 = "Starter manuel slot 3. Le rapport JSON exporte ensuite le trio choisi avec les noms FR et EN."
            PatchStarters = "Patch des équipes liees au choix du starter: après avoir change les 3 starters visibles, le script lit les données vanilla, retrouve tous les slots des familles Ouistempo / Flambino / Larmeleon, puis force ces slots vers le trio final. Ca marche même si les Pokémon des dresseurs ont été randomises avant, et les slots patches reconstruisent maintenant aussi leurs attaques pour éviter de garder les moves de l'ancienne espèce."
            ReportLanguage = "Langue du JSON: choisit la langue principale des libelles du rapport exporte. La saisie des noms de starters accepte toujours FR et EN."
            UiLanguage = "Langue du logiciel: change a chaud les textes de l'interface et les descriptions d'aide entre français et anglais."
            EvolutionMode = "Cibles d'évolution: Random complet remappe les évolutions librement. Random equilibre (BST proche) garde des cibles de puissance proche. Exemple: Empiflor peut évoluer vers Pingoleon si le mode le permet."
            AllowLegendaryEvo = "Autoriser légendaires en évolution: ajoute les légendaires et mythiques dans les cibles d'évolution randomisées. Laisse décoche pour une progression plus classique."
            NormalizeFriendship = "Normalisation amitie: convertit les methodes d'amitie en évolution simple par niveau. Methodes couvertes: 1, 2, 3."
            NormalizeTrade = "Normalisation échange: convertit échange simple, échange avec objet et échange contre espèce spécifique en évolution simple par niveau. Methodes couvertes: 5, 6, 7."
            NormalizeSpecial = "Normalisation des évolutions chelou: convertit toutes les methodes non vides qui ne sont pas déjà une évolution niveau pur en évolution par niveau fixe. Ca couvre temps, beaute, lieu, objet/pierre, attaque connue, sexe/meteo/équipe et autres conditions spéciales. Si tu veux garder les évolutions par pierre/objet, ne coche pas cette option."
            GiftMode = "Pokemon cadeaux: modifie les cadeaux non starters dans add_poke.bin. Random complet ignore la puissance; Random equilibre (BST proche) garde une puissance proche."
            AllowLegendaryGifts = "Autoriser les légendaires pour gifts et starters: ajoute les légendaires et mythiques dans les pools de remplacement des cadeaux et starters."
            TradeMode = "Trades PNJ: modifie les espèces des échanges PNJ. Le Pokémon demande et le Pokémon recu peuvent être randomises quand le fichier les expose."
            AllowLegendaryTrades = "Autoriser légendaires dans les trades PNJ: ajoute les légendaires et mythiques dans les pools de remplacement des échanges PNJ."
            StaticMode = "Rencontres fixes: agit sur les rencontres scriptes et statiques du fichier event_encount_data.bin."
            AllowLegendaryStatic = "Autoriser légendaires en rencontres fixes: ajoute les légendaires et mythiques dans les pools des rencontres fixes/scriptes."
            GrassMode = "Espèces des rencontres sauvages: contrôle les tables ROMFS utilisees par les hautes herbes, les symboles visibles et les rencontres de terrain. Garder vanilla ne touche pas aux espèces des tables; l'option ci-dessous peut quand même separer ce que tu vois dehors de ce que tu combats."
            AllowLegendaryGrass = "Autoriser légendaires en herbes / visibles: ajoute les légendaires et mythiques dans les pools de remplacement des hautes herbes cachees et des Pokémon visibles en overworld."
            StaticStableMapping = "Mapping statiques: Espèce transforme toutes les mêmes espèces vanilla vers le même remplacement. Slot tire chaque entrée statique/script independamment. Ni l'un ni l'autre ne reroll les rencontres en direct dans le jeu."
            GrassStableMapping = "Règle de mapping sauvage: Stable par espèce signifie que tous les Pikachu vanilla d'une zone deviennent le même remplacement. Stable par slot tire chaque entrée séparément, donc le Pikachu d'une route et celui d'une autre zone peuvent devenir deux espèces différentes."
            VisibleEncounterBehavior = "Pokémon visibles dehors: Masque fixe ne réécrit jamais le modèle overworld et change seulement la copie de combat. Revelation permanente garde le premier résultat cache pour cette zone/source, puis affiche et combat ce même résultat. Classique coupe la couche runtime cachee."
            EncounterDrawMode = "Mode de tirage rencontres: Slot par espèce associe chaque espèce/form source d'une zone a un résultat stable. Full random reroll les entrées ROMFS visibles et les combats independamment. Visible fixe + tirage random garde les sprites ROMFS et reroll seulement le combat."
            LiveVisibleMode = "Pokémon que tu VOIS dehors [NÉCESSITE EXEFS]: Inchangé / Aléatoire a chaque apparition / Stable par zone / Stable partout / Découverte de zones."
            LiveBattleMode = "Pokémon que tu AFFRONTES [NÉCESSITE EXEFS]: règle-le differemment du visible pour obtenir le combat cache."
            LiveGenerationFilter = "Générations autorisees au tirage runtime, separees par des virgules. Exemple : 1,2,3"
            UndergroundMode = "Underground: modifie les slots d'espèces du souterrain, stockes separement des rencontres normales de terrain."
            AllowLegendaryUnderground = "Autoriser légendaires en underground: ajoute les légendaires et mythiques dans les pools de remplacement du souterrain."
            DisableExpShare = "EXP Share par défaut: OFF: écrit enabled=false dans la config ExLaunch [exp_share] générée. Si le menu PC runtime est active, c'est seulement l'état de départ et le joueur peut le changer en jeu."
            EarlyBike = "Velo Rotom des le début: écrit active=true dans la config ExLaunch [early_bike]. Le module ajoute une fois le vrai objet rare Velo Rotom quand le terrain est charge."
            RuntimePcControls = "Menu PC pour changer en jeu: remplace le script du PC du Centre Pokémon uniquement si cette option est cochee. Cette option ne désactivé pas l'EXP Share toute seule; elle permet seulement de modifier les options runtime en jeu. Décoche, le menu PC vanilla reste intact et les options du logiciel sont appliquées directement."
            DynamicExpLevelCap = "Levelcap EXP dynamique: n'écrit plus l'ancien IPS brut. Le chemin fiable passe par ExLaunch a la fin du calcul EXP. L'outil deploie le main.npdm ExLaunch-compatible du projet avec le module custom subsdk9."
            StrictBossMaxLevelCap = "Cap boss max strict: calcule toujours les caps et peut normaliser les équipes boss listées, mais le blocage EXP en jeu requiert maintenant le module ExLaunch. L'outil deploie le main.npdm ExLaunch-compatible du projet avec le module custom subsdk9. Sans ce module, le JSON sert de référence et l'EXP n'est pas bloquee."
            MainStorySoftLevelCap = "Cap progression principale souple: chaque palier prend le niveau max des gros combats du meme bloc de badges. MESURE DU 2026-09-07 : sur les 50 combats majeurs d'Epee, le champion d'arene est le plus fort de sa fenetre a chaque fois - les rivaux sont 1 a 4 niveaux en dessous. Cette option rend donc EXACTEMENT les memes 9 paliers que le cap arenes/ligue, et le generateur le signale. Elle est conservee pour les scripts existants; le detail reste exporte dans story-main-progression-soft-caps.json."
            GymLeagueStoryLevelCap = "Cap EXP histoire arènes/Tarak: calcule une table de 9 caps depuis les vraies équipes générées. L'application en jeu requiert ExLaunch. L'outil deploie le main.npdm ExLaunch-compatible du projet avec le module custom subsdk9."
            StoryMajorBattleOrderLevelCap = "Mode ordre histoire principale: garde le patch EXP dynamique global puis normalise une liste fixe et ordonnee des gros combats de l'histoire principale sur le niveau max de chaque equipe apres randomisation. Ca couvre les arenes plus les combats majeurs de Nabil, Travis, Rosemary, Liv, Shehroz et Tarak, exportes dans story-major-battle-caps.json, avec toutes les variantes dependantes du starter ou de la version presentes dans les donnees dresseurs. Ca repose encore sur une liste ordonnee preparee a la main, pas sur un lecteur temps reel de l'etat cache du scenario."
            AutoInstallToEden = "Installation auto vers les émulateurs coches et detectes: après la génération, l'outil tente de copier romfs, exefs et le sous-arbre sdmc généré vers tous les émulateurs coches et trouves sur le PC."
            EdenModName = "Nom du dossier de mod installe: contrôle le nom final du dossier de mod dans le chemin load/mods propre a chaque émulateur. Garde Randomizer si tu veux simplement remplacer la run précédente."
            InstallTargetRyujinx = "Installer vers Ryujinx: utilise %AppData%\\Ryujinx\\mods\\contents\\<titleId>\\<nomDuMod> plus %AppData%\\Ryujinx\\sdcard\\config\\swsh-mods-exl\\config.toml. Les anciennes installations sdcard\\atmosphere\\contents sont nettoyees automatiquement."
            ValidateBuild = "Validation du build: vérifie les dossiers source, les fichiers ROMFS requis, le besoin ExeFS pour les options runtime, les plages numeriques et les incompatibilites evidentes avant génération. Exemple: si les combats visibles caches sont actives sans dump ExeFS, la génération est bloquee avant d'écrire un mod casse."
            BuildSummary = "Résumé du build: ouvre la même page 'ce qui va être modifie' que celle affichée avant génération. Exemple: avant d'écrire les fichiers, tu vois si dresseurs, rencontres, EXP Share, ExLaunch, options Smogon et installations émulateur seront changes."
        }
    }
}

function Get-RandomizerHelpText {
    param(
        [string]$Language = "fr",
        [string]$GameVersion = "Sword",
        [string]$ModName = "Randomizer",
        [string]$OutputRomfsRoot = ""
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $ui = Get-UiStrings -Language $lang
    Add-ConcreteDescriptionExamples -Ui $ui -Language $lang

    $labels = $ui.Labels
    $descriptions = $ui.Descriptions
    $lines = New-Object System.Collections.Generic.List[string]

    $addLine = {
        param([string]$Text = "")
        [void]$lines.Add($Text)
    }
    $addSection = {
        param([string]$Title)
        & $addLine ""
        & $addLine ("=== {0} ===" -f $Title)
    }
    $addOption = {
        param(
            [string]$Label,
            [string]$Description
        )
        if (-not [string]::IsNullOrWhiteSpace($Label) -and -not [string]::IsNullOrWhiteSpace($Description)) {
            & $addLine ("- {0}: {1}" -f $Label, $Description)
        }
    }
    $addKey = {
        param(
            [string]$Key,
            [string]$Fallback = ""
        )
        $label = [string]$labels[$Key]
        $description = [string]$descriptions[$Key]
        if ([string]::IsNullOrWhiteSpace($description)) {
            $description = $Fallback
        }
        & $addOption $label $description
    }

    if ($lang -eq "en") {
        & $addLine "PokeFeur Randomizer help"
        & $addLine "Every option below is generated from the same labels/descriptions used by the interface. Examples use Victreebel and Empoleon so the behavior stays concrete."
        & $addSection "Main build"
        & $addOption $ui.SourceLabel "Folder from the user's ROMFS dump. Example: select the romfs folder from Pokemon Sword/Shield; if the expected SWSH files are missing, generation must stop instead of producing a broken mod."
        & $addOption $ui.SourceExefsLabel "Folder from the user's ExeFS dump. Example: select the exefs folder next to your dump when a runtime flow asks for it. The shipped ExLaunch package now provides its own compatible main.npdm/subsdk9 payloads."
        & $addOption $ui.OutputLabel "Root folder where the generated mod is written. Example: choosing output\\Sword always creates romfs there; exefs and sdmc are added only when an ExeFS folder is explicitly provided for ExLaunch/runtime features."
        & $addOption $ui.GameVersion "Chooses the title ID and version-specific install paths. Example: Sword and Shield use different emulator content folders."
        & $addOption $ui.Seed "Controls repeatability. Example: seed 123 always produces the same Victreebel to Empoleon style mappings; -1 creates a new random seed."
        & $addOption $ui.UiLanguage "Changes the software language immediately."
        & $addOption $ui.ReportLanguage "Changes labels in JSON reports without changing the randomization itself."
        & $addOption $ui.Theme "Switches the interface theme."
        & $addOption $ui.ValidateBuild $descriptions.ValidateBuild
        & $addOption $ui.BuildSummary $descriptions.BuildSummary
        & $addOption $ui.Generate "Builds the mod from the user ROMFS/ExeFS folders and current options."
        & $addOption "Export preset / Import preset" "Preset JSON saves and restores the software configuration only. Example: export your trainer/encounter settings, then import them later before generating another run."
    } else {
        & $addLine "Aide du PokeFeur Randomizer"
        & $addLine "Chaque option ci-dessous reprend les mêmes libelles/descriptions que l'interface. Les exemples utilisent Empiflor et Pingoleon pour que l'effet soit concret."
        & $addSection "Generation principale"
        & $addOption $ui.SourceLabel "Dossier romfs du dump utilisateur. Exemple: sélectionne le dossier romfs de Pokémon Épée/Bouclier; si les fichiers SWSH attendus manquent, la génération doit s'arreter au lieu de sortir un mod casse."
        & $addOption $ui.SourceExefsLabel "Dossier exefs du dump utilisateur. Exemple: sélectionne le dossier exefs a cote de ton dump quand un flux runtime le demande. Le package ExLaunch fourni embarque maintenant son propre couple main.npdm/subsdk9 compatible."
        & $addOption $ui.OutputLabel "Dossier racine ou le mod genere est ecrit. Exemple: choisir output\\Epee cree toujours romfs dedans; exefs et sdmc ne sont ajoutes que si un dossier ExeFS est explicitement fourni pour les options ExLaunch/runtime."
        & $addOption $ui.GameVersion "Choisit le title ID et les chemins d'installation selon le jeu. Exemple: Épée et Bouclier n'utilisent pas le même dossier de contenu émulateur."
        & $addOption $ui.Seed "Contrôle la reproductibilite. Exemple: seed 123 redonne toujours les mêmes mappings du style Empiflor vers Pingoleon; -1 cree un nouveau tirage."
        & $addOption $ui.UiLanguage "Change immédiatement la langue du logiciel."
        & $addOption $ui.ReportLanguage "Change la langue des libelles dans les rapports JSON sans changer la randomisation."
        & $addOption $ui.Theme "Change le thème visuel du logiciel."
        & $addOption $ui.ValidateBuild $descriptions.ValidateBuild
        & $addOption $ui.BuildSummary $descriptions.BuildSummary
        & $addOption $ui.Generate "Genere le mod depuis les dossiers ROMFS/ExeFS utilisateur et les options actuelles."
        & $addOption "Exporter preset / Importer preset" "Le preset JSON sauvegarde et restaure seulement la configuration du logiciel. Exemple: exporte tes réglages dresseurs/rencontres, puis importe-les plus tard avant une autre génération."
    }

    & $addSection $ui.Tabs.General
    foreach ($key in @("DisableExpShare", "GymLeagueStoryLevelCap", "RuntimePcControls", "AutoInstallToEden", "EdenModName", "InstallTargetRyujinx")) {
        & $addKey $key
    }

    & $addSection $ui.Tabs.Trainers
    foreach ($key in @(
        "TrainerSpecies", "TrainerMoves", "TrainerSmogonMoveFallback", "TrainerItems", "TrainerItemPool", "TrainerAbility", "TrainerIV", "TrainerEV", "TrainerAddedSlotSpecies", "TrainerDuplicateMode",
        "TrainerLevel", "TrainerTeamSize", "ForceAllTeams", "ForceBossTeams", "BossTeamsScope", "RandomizeNatures", "AllowLegendaryTrainers", "TrainerShinyChance",
        "TrainerExtraPokemon", "TrainerSpecialRuleScope", "TrainerLegendaryPolicy", "TrainerMinBaseStatTotal",
        "TrainerTypeThemed", "ForceTrainerFullyEvolved", "TrainerDynamaxLevel", "ForceTrainerCanDynamax", "MaxTrainerAI"
    )) {
        & $addKey $key
    }
    if ($lang -eq "en") {
        & $addOption $labels.TrainerTeamMin "Minimum trainer party size. Example: 3 forces tiny teams upward to at least 3 Pokemon."
        & $addOption $labels.TrainerTeamMax "Maximum trainer party size. Example: 4 prevents regular trainers from going above 4 Pokemon unless a 6-Pokemon helper applies first."
        & $addOption $labels.TrainerFullyEvolvedLevel "Level used by Force final evolutions. Example: 40 means Empoleon-style final stages are forced from level 40 onward."
    } else {
        & $addOption $labels.TrainerTeamMin "Taille minimum des équipes de dresseurs. Exemple: 3 remonte les petites équipes a au moins 3 Pokémon."
        & $addOption $labels.TrainerTeamMax "Taille maximum des équipes de dresseurs. Exemple: 4 empêche les dresseurs classiques de depasser 4 Pokémon sauf si une aide équipe a 6 s'applique avant."
        & $addOption $labels.TrainerFullyEvolvedLevel "Niveau utilise par Forcer les évolutions finales. Exemple: 40 force les stades finaux comme Pingoleon a partir du niveau 40."
    }

    & $addSection $ui.Tabs.Pokemon
    foreach ($key in @(
        "TypeMode", "TypesMonotypeOnly", "AbilityMode", "AllowWonderGuard", "StatMode", "ExpYieldMultiplier", "ForceOneExpYield",
        "MoveTypeMode", "MovePowerMode", "MovePPMode", "MoveAccuracyMode", "MoveCategoryMode"
    )) {
        & $addKey $key
    }
    if ($lang -eq "en") {
        & $addOption $labels.MovePowerMin "Minimum power used when move power is randomized. Example: 40 prevents weak damaging moves from rolling below 40 power."
        & $addOption $labels.MovePowerMax "Maximum power used when move power is randomized. Example: 120 prevents random moves from becoming absurdly strong."
        & $addOption $labels.MovePPMin "Minimum PP used when move PP is randomized."
        & $addOption $labels.MovePPMax "Maximum PP used when move PP is randomized."
        & $addOption $labels.MoveAccuracyMin "Minimum accuracy used when move accuracy is randomized."
        & $addOption $labels.MoveAccuracyMax "Maximum accuracy used when move accuracy is randomized."
    } else {
        & $addOption $labels.MovePowerMin "Puissance minimum quand la puissance des attaques est randomisée. Exemple: 40 empêche les attaques offensives de tomber sous 40."
        & $addOption $labels.MovePowerMax "Puissance maximum quand la puissance des attaques est randomisée. Exemple: 120 evite des attaques random absurdes."
        & $addOption $labels.MovePPMin "PP minimum quand les PP des attaques sont randomises."
        & $addOption $labels.MovePPMax "PP maximum quand les PP des attaques sont randomises."
        & $addOption $labels.MoveAccuracyMin "Précision minimum quand la précision des attaques est randomisée."
        & $addOption $labels.MoveAccuracyMax "Précision maximum quand la précision des attaques est randomisée."
    }

    & $addSection $ui.Tabs.Evolutions
    foreach ($key in @("EvolutionMode", "AllowLegendaryEvo", "NormalizeFriendship", "NormalizeTrade", "NormalizeSpecial")) {
        & $addKey $key
    }
    if ($lang -eq "en") {
        & $addOption $labels.FriendshipLevel "Level used after converting friendship evolutions. Example: if set to 30, that evolution happens at level 30."
        & $addOption $labels.TradeLevel "Level used after converting trade evolutions. Example: if set to 36, the old trade evolution becomes level 36."
        & $addOption $labels.SpecialLevel "Level used after converting special evolutions such as location, weather or item conditions."
    } else {
        & $addOption $labels.FriendshipLevel "Niveau utilise après conversion des évolutions par amitie. Exemple: si tu mets 30, l'évolution arrive au niveau 30."
        & $addOption $labels.TradeLevel "Niveau utilise après conversion des évolutions par échange. Exemple: si tu mets 36, l'ancienne évolution par échange devient niveau 36."
        & $addOption $labels.SpecialLevel "Niveau utilise après conversion des évolutions spéciales comme lieu, meteo ou condition d'objet."
    }

    & $addSection $ui.Tabs.Gifts
    foreach ($key in @("StarterMode", "Starter1", "Starter2", "Starter3", "PatchStarters", "GiftMode", "NpcGiftItemMode", "AllowLegendaryGifts", "TradeMode", "AllowLegendaryTrades")) {
        & $addKey $key
    }
    if ($lang -eq "en") {
        & $addOption "Manual starters" "Leave all 3 boxes empty to use the starter mode. Fill all 3 boxes to force the exact trio, for example Victreebel / Empoleon / Victreebel."
    } else {
        & $addOption "Starters manuels" "Laisse les 3 champs vides pour utiliser le mode starters. Remplis les 3 champs pour imposer exactement le trio, par exemple Empiflor / Pingoleon / Empiflor."
    }

    & $addSection $ui.Tabs.Encounters
    foreach ($key in @(
        "StaticMode", "AllowLegendaryStatic", "StaticStableMapping", "GrassMode", "AllowLegendaryGrass", "GrassStableMapping",
        "VisibleEncounterBehavior", "EncounterDrawMode",
        "LiveVisibleMode", "LiveBattleMode", "LiveGenerationFilter",
        "UndergroundMode", "AllowLegendaryUnderground"
    )) {
        & $addKey $key
    }

    if ($lang -eq "en") {
        & $addSection "Mode values"
        & $addLine "- Full random: any allowed Pokemon can be picked. Example: Victreebel can become Empoleon."
        & $addLine "- Balanced random (similar BST): keeps replacements close in total base stats. Example: weak early Pokemon stay closer to early-game power."
        & $addLine "- Keep vanilla: leaves that data unchanged."
        & $addLine "- Stable by slot: each table slot gets its own stable result. Example: Route 4 Victreebel can map to Empoleon while another Victreebel elsewhere maps differently."
        & $addLine "- Stable by species: the same vanilla species maps to the same result everywhere. Example: every Victreebel becomes Empoleon."
        & $addLine "- Fresh roll per encounter entry: the build makes fresh rolls for encounter entries; it is the chaotic mode."
        & $addLine "- Classic visible = battle: what you see outside is what you fight."
        & $addLine "- Locked hidden battle: the outside model stays unchanged and the same visible Pokemon repeats the same hidden battle by mapping rule."
        & $addLine "- Revealed-stable hidden battle: the hidden battle can become visible once, then stops rerolling."
        & $addLine "- Full random: the visible-table layer and battle layer use independent random rolls."
    } else {
        & $addSection "Valeurs des menus"
        & $addLine "- Random complet: n'importe quel Pokemon autorise peut etre tire. Exemple: Empiflor peut devenir Pingoleon."
        & $addLine "- Random equilibre (BST proche): garde une puissance globale proche. Exemple: un Pokémon faible de début de jeu reste dans une puissance comparable."
        & $addLine "- Garder vanilla: ne modifie pas ces données."
        & $addLine "- Stable par slot: chaque slot de table garde son propre résultat. Exemple: l'Empiflor d'une route peut devenir Pingoleon pendant qu'un autre Empiflor ailleurs devient autre chose."
        & $addLine "- Stable par espèce: la même espèce vanilla devient le même remplacement partout. Exemple: tous les Empiflor deviennent Pingoleon."
        & $addLine "- Tirage frais par entrée: la génération fait un tirage frais pour chaque entrée de rencontre; c'est le mode chaotique."
        & $addLine "- Classique visible = combat: tu combats ce que tu vois dehors."
        & $addLine "- Combat cache verrouille: le modèle dehors reste inchangé et le même Pokémon visible repete le même combat cache selon la règle de mapping."
        & $addLine "- Combat cache révélé stable: le combat cache peut devenir visible une fois, puis arrête de reroll."
        & $addLine "- Full random: la couche visible et la couche combat utilisent des tirages independants."
    }

    & $addSection $ui.Tabs.Reset
    if ($lang -eq "en") {
        & $addOption $labels.ResetTargets "Choose which detected emulator installs should be cleaned."
        & $addOption $labels.ResetButton "Deletes only generated mod files for the selected emulator targets."
    } else {
        & $addOption $labels.ResetTargets "Choisit quelles installations emulateur detectees doivent etre nettoyees."
        & $addOption $labels.ResetButton "Supprime uniquement les fichiers de mod générés pour les émulateurs selectionnes."
    }
    & $addLine $labels.ResetDefault

    $installTitle = if ($lang -eq "en") { "Install paths" } else { "Chemins d'installation" }
    & $addSection $installTitle
    & $addLine (Get-InstallationGuideText -Language $lang -GameVersion $GameVersion -ModName $ModName -OutputRomfsRoot $OutputRomfsRoot)

    return ($lines -join [Environment]::NewLine)
}

function Set-LocalizedComboItems {
    param(
        [System.Windows.Forms.ComboBox]$Combo,
        [array]$Items
    )

    $currentValue = Get-ComboValue -Combo $Combo
    $Combo.Items.Clear()
    foreach ($item in $Items) {
        Add-ComboBoxItem -Combo $Combo -Label $item.Label -Value $item.Value
    }
    $Combo.DisplayMember = "Label"

    if ($currentValue) {
        for ($i = 0; $i -lt $Combo.Items.Count; $i++) {
            if ($Combo.Items[$i].Value -eq $currentValue) {
                $Combo.SelectedIndex = $i
                return
            }
        }
    }

    if ($Combo.Items.Count -gt 0) {
        $Combo.SelectedIndex = 0
    }
}

function Get-NormalizedGuiTheme {
    param([string]$Theme)

    $value = ([string]$Theme).Trim().ToLowerInvariant()
    if ($value -in @("dark", "sombre", "noir")) {
        return "Dark"
    }

    return "Light"
}

function Get-GuiThemePalette {
    param([string]$Theme)

    if ((Get-NormalizedGuiTheme -Theme $Theme) -eq "Dark") {
        # Memes valeurs que PokeFeur.Ui.PfTheme : les deux moities de
        # l'interface (controles dessines et controles encore systeme) doivent
        # parler la meme langue, sinon la fenetre a l'air d'un collage.
        # Panel et Surface valent la couleur de carte : c'est ce qui rend
        # invisibles les rectangles de fond des libelles, qui sont poses sur le
        # formulaire mais s'affichent au-dessus des panneaux.
        return @{
            Name = "Dark"
            Form = [System.Drawing.Color]::FromArgb(28, 29, 33)
            Panel = [System.Drawing.Color]::FromArgb(34, 36, 41)
            Surface = [System.Drawing.Color]::FromArgb(34, 36, 41)
            Input = [System.Drawing.Color]::FromArgb(24, 25, 29)
            InputReadOnly = [System.Drawing.Color]::FromArgb(41, 43, 50)
            Button = [System.Drawing.Color]::FromArgb(34, 36, 41)
            PrimaryButton = [System.Drawing.Color]::FromArgb(59, 111, 224)
            Text = [System.Drawing.Color]::FromArgb(238, 240, 244)
            MutedText = [System.Drawing.Color]::FromArgb(152, 158, 170)
            Border = [System.Drawing.Color]::FromArgb(50, 53, 61)
            SelectedTab = [System.Drawing.Color]::FromArgb(34, 36, 41)
            TabHeader = [System.Drawing.Color]::FromArgb(28, 29, 33)
            Accent = [System.Drawing.Color]::FromArgb(96, 145, 255)
            AccentSoft = [System.Drawing.Color]::FromArgb(41, 43, 50)
            Gold = [System.Drawing.Color]::FromArgb(233, 178, 82)
            Green = [System.Drawing.Color]::FromArgb(74, 201, 138)
            Red = [System.Drawing.Color]::FromArgb(240, 110, 110)
            Pink = [System.Drawing.Color]::FromArgb(226, 128, 186)
            Purple = [System.Drawing.Color]::FromArgb(167, 139, 250)
        }
    }

    # Le theme clair se contentait des couleurs systeme : autant dire qu'il
    # n'existait pas. Il est desormais concu, et symetrique du sombre.
    return @{
        Name = "Light"
        Form = [System.Drawing.Color]::FromArgb(246, 247, 249)
        Panel = [System.Drawing.Color]::FromArgb(255, 255, 255)
        Surface = [System.Drawing.Color]::FromArgb(255, 255, 255)
        Input = [System.Drawing.Color]::FromArgb(250, 251, 252)
        InputReadOnly = [System.Drawing.Color]::FromArgb(238, 241, 246)
        Button = [System.Drawing.Color]::FromArgb(255, 255, 255)
        PrimaryButton = [System.Drawing.Color]::FromArgb(38, 88, 200)
        Text = [System.Drawing.Color]::FromArgb(24, 27, 33)
        MutedText = [System.Drawing.Color]::FromArgb(94, 101, 114)
        Border = [System.Drawing.Color]::FromArgb(219, 223, 230)
        SelectedTab = [System.Drawing.Color]::FromArgb(255, 255, 255)
        TabHeader = [System.Drawing.Color]::FromArgb(246, 247, 249)
        Accent = [System.Drawing.Color]::FromArgb(45, 98, 214)
        AccentSoft = [System.Drawing.Color]::FromArgb(232, 238, 250)
        Gold = [System.Drawing.Color]::FromArgb(163, 112, 20)
        Green = [System.Drawing.Color]::FromArgb(28, 138, 88)
        Red = [System.Drawing.Color]::FromArgb(190, 58, 58)
        Pink = [System.Drawing.Color]::FromArgb(168, 62, 124)
        Purple = [System.Drawing.Color]::FromArgb(94, 70, 170)
    }
}

function Enable-GuiDoubleBuffer {
    param([System.Windows.Forms.Control]$Control)

    if (-not $Control) {
        return
    }

    try {
        $prop = [System.Windows.Forms.Control].GetProperty("DoubleBuffered", [System.Reflection.BindingFlags] "Instance, NonPublic")
        if ($prop) {
            $prop.SetValue($Control, $true, $null)
        }
    } catch {
    }
}

function Add-PokeFeurBackground {
    param([System.Windows.Forms.Form]$Form)

    # Fond uni. Le quadrillage et les halos coloriaient chaque pixel derriere
    # l'interface : c'est ce qui donnait a la fenetre son air de theme
    # personnalise plutot que de logiciel.
    $Form.Add_Paint({
        param($sender, $eventArgs)
        $palette = Get-GuiThemePalette -Theme $script:GuiTheme
        $eventArgs.Graphics.Clear($palette.Form)
    })
}

function Apply-GuiThemeToControl {
    param(
        [System.Windows.Forms.Control]$Control,
        [hashtable]$Palette
    )

    if (-not $Control) {
        return
    }

    # Les controles dessines portent leur propre theme : forcer BackColor,
    # ForeColor ou FlatStyle dessus ecraserait le rendu qu'ils calculent. On les
    # laisse tranquilles, mais on continue de descendre dans leurs enfants.
    if ($Control.GetType().FullName -like "PokeFeur.Ui.*") {
        foreach ($child in $Control.Controls) {
            Apply-GuiThemeToControl -Control $child -Palette $Palette
        }
        $Control.Invalidate()
        return
    }

    if ($Control -is [System.Windows.Forms.Form]) {
        $Control.BackColor = $Palette.Form
        $Control.ForeColor = $Palette.Text
        $Control.Font = New-GuiFont -Size 9.5
    } elseif ($Control -is [System.Windows.Forms.TabPage] -or $Control -is [System.Windows.Forms.Panel] -or $Control -is [System.Windows.Forms.GroupBox]) {
        $tag = [string]$Control.Tag
        if ($tag -eq "HeaderPanel") {
            $Control.BackColor = $Palette.Surface
        } elseif ($tag -eq "ChromePanel") {
            $Control.BackColor = $Palette.Panel
        } elseif ($tag -eq "ActionPanel") {
            $Control.BackColor = $Palette.Surface
        } else {
            $Control.BackColor = $Palette.Panel
        }
        $Control.ForeColor = $Palette.Text
        if ($Control -is [System.Windows.Forms.GroupBox]) {
            $Control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        }
    } elseif ($Control -is [System.Windows.Forms.TextBox]) {
        $Control.BackColor = if ($Control.ReadOnly) { $Palette.InputReadOnly } else { $Palette.Input }
        $Control.ForeColor = $Palette.Text
        $Control.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    } elseif ($Control -is [System.Windows.Forms.ComboBox]) {
        $Control.BackColor = $Palette.Input
        $Control.ForeColor = $Palette.Text
        $Control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    } elseif ($Control -is [System.Windows.Forms.Button]) {
        $Control.UseVisualStyleBackColor = $false
        $Control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $Control.BackColor = if ([string]$Control.Tag -eq "PrimaryButton") { $Palette.PrimaryButton } else { $Palette.Button }
        $Control.ForeColor = $Palette.Text
        $Control.FlatAppearance.BorderColor = if ([string]$Control.Tag -eq "PrimaryButton") { $Palette.Accent } else { $Palette.Border }
        $Control.FlatAppearance.MouseOverBackColor = if ([string]$Control.Tag -eq "PrimaryButton") { $Palette.AccentSoft } else { $Palette.SelectedTab }
        $Control.FlatAppearance.MouseDownBackColor = $Palette.Input
        $Control.FlatAppearance.BorderSize = 1
        $Control.FlatAppearance.BorderSize = if ([string]$Control.Tag -eq "PrimaryButton") { 0 } else { 1 }
        if ([string]$Control.Tag -eq "PrimaryButton") {
            $Control.ForeColor = [System.Drawing.Color]::White
            $Control.Font = [PokeFeur.Ui.PfFont]::Get("display", 11, [System.Drawing.FontStyle]::Bold)
        } else {
            $Control.Font = [PokeFeur.Ui.PfFont]::BodyBold
        }
    } elseif ($Control -is [System.Windows.Forms.CheckBox]) {
        $Control.UseVisualStyleBackColor = $false
        $Control.BackColor = $Palette.Panel
        $Control.ForeColor = $Palette.Text
    } elseif ($Control -is [System.Windows.Forms.Label]) {
        # Transparent ne fonctionne pas ici : WinForms peint alors la couleur du
        # PARENT, qui est le formulaire, alors que le libelle est visuellement
        # pose sur un panneau. On obtenait un rectangle plus clair derriere
        # chaque texte. Prendre la couleur de carte le rend invisible.
        $Control.BackColor = $Palette.Panel
        $Control.ForeColor = $Palette.MutedText
        if ([string]$Control.Tag -eq "BrandPoke") {
            # Bleu vif + or a 22 points : c'etait la signature la plus datee de
            # la fenetre. Un seul accent, une seule graisse, taille reduite.
            $Control.ForeColor = $Palette.Text
            $Control.Font = [PokeFeur.Ui.PfFont]::Get("display", 18, [System.Drawing.FontStyle]::Bold)
        } elseif ([string]$Control.Tag -eq "BrandFeur") {
            $Control.ForeColor = $Palette.Accent
            $Control.Font = [PokeFeur.Ui.PfFont]::Get("display", 18, [System.Drawing.FontStyle]::Bold)
        } elseif ([string]$Control.Tag -eq "HeroSub") {
            $Control.ForeColor = $Palette.MutedText
            $Control.Font = [PokeFeur.Ui.PfFont]::Small
        } elseif ([string]$Control.Tag -eq "Title") {
            $Control.ForeColor = $Palette.Text
            $Control.Font = [PokeFeur.Ui.PfFont]::H1
        } elseif ([string]$Control.Tag -eq "Accent") {
            $Control.ForeColor = $Palette.Purple
        } elseif ([string]$Control.Tag -eq "InputLabel") {
            $Control.ForeColor = $Palette.MutedText
            $Control.Font = [PokeFeur.Ui.PfFont]::BodyBold
        }
    } elseif ($Control -is [System.Windows.Forms.TabControl]) {
        $Control.BackColor = $Palette.Form
        $Control.ForeColor = $Palette.Text
    } else {
        $Control.BackColor = $Palette.Form
        $Control.ForeColor = $Palette.Text
    }

    foreach ($child in $Control.Controls) {
        Apply-GuiThemeToControl -Control $child -Palette $Palette
    }
}

function Apply-GuiTheme {
    param(
        [System.Windows.Forms.Control]$Root,
        [string]$Theme
    )

    $script:GuiTheme = Get-NormalizedGuiTheme -Theme $Theme
    # Les controles dessines lisent leurs couleurs dans PfTheme : il faut le
    # basculer avant de repeindre, sinon ils gardent l'ancien theme.
    Initialize-PfControlLibrary
    if ($script:GuiTheme -eq "Dark") {
        [PokeFeur.Ui.PfTheme]::UseDark()
    } else {
        [PokeFeur.Ui.PfTheme]::UseLight()
    }
    $palette = Get-GuiThemePalette -Theme $script:GuiTheme
    Apply-GuiThemeToControl -Control $Root -Palette $palette
    $Root.Refresh()
}


function Update-PfCards {
    <#
        Recopie titres et sous-titres dans les cartes. Appelee au changement de
        langue : une carte ne se traduit pas toute seule.
    #>
    $estAnglais = ($script:UiLanguage -eq "en")
    foreach ($entree in @($script:PfCardRegistry)) {
        if (-not $entree -or -not $entree.Card) { continue }
        if ($entree.TitleSource) {
            $entree.Card.Title = [string]$entree.TitleSource.Text
        } elseif ($estAnglais -and $entree.TitleEn) {
            $entree.Card.Title = $entree.TitleEn
        } elseif ($entree.TitleFr) {
            $entree.Card.Title = $entree.TitleFr
        }
        if ($entree.SubtitleSource) {
            $entree.Card.Subtitle = [string]$entree.SubtitleSource.Text
        }
        $entree.Card.Invalidate()
    }
}

function Update-PfRailLabels {
    <#
        Recopie les libelles d'onglets dans le rail. Appelee quand la langue
        change : le rail est construit apres les onglets et ne suit pas tout
        seul.
    #>
    if (-not $script:PfNavRail -or -not $script:PfTabs) {
        return
    }
    # Les deux intitules de groupe etaient ecrits en dur en francais : ils
    # restaient francais meme quand tout le reste passait en anglais.
    $randomGroup = if ($script:UiLanguage -eq "en") { "Randomization" } else { "Randomisation" }
    $moduleGroup = if ($script:UiLanguage -eq "en") { "Module and upkeep" } else { "Module et entretien" }
    for ($i = 0; $i -lt $script:PfTabs.TabPages.Count; $i++) {
        if ($i -lt $script:PfNavRail.Items.Count) {
            $script:PfNavRail.Items[$i].Label = [string]$script:PfTabs.TabPages[$i].Text
            $script:PfNavRail.Items[$i].Group = if ($i -lt 6) { $randomGroup } else { $moduleGroup }
        }
    }
    $script:PfNavRail.Invalidate()
    if ($script:PfPageTitle -and $script:PfTabs.TabPages.Count -gt 0) {
        $script:PfPageTitle.Text = [string]$script:PfTabs.TabPages[$script:PfTabs.SelectedIndex].Text
    }
}

function Add-PfCardAround {
    <#
        Enveloppe dans une carte tous les controles d'un onglet dont le haut
        tombe dans une plage verticale.

        Pourquoi un helper plutot que reecrire chaque onglet : les positions
        sont ecrites en dur, et neuf onglets font plusieurs centaines de
        coordonnees. Ici on ne recalcule rien - les controles gardent leurs
        positions RELATIVES, tout le groupe est simplement translate dans la
        carte. La seule chose qui change est l'origine.

        PfCard peint son titre dans 20..44 et son sous-titre dans 44..64 : le
        contenu commence donc a 46 sans sous-titre, 72 avec. Un test verifie
        cette regle (tests/Interface.Tests.ps1).
    #>
    param(
        [System.Windows.Forms.Control]$Parent,
        [int]$FromY,
        [int]$ToY,
        # Decoupe par colonne, pour les onglets trop hauts pour etre coupes en
        # tranches horizontales : Pokemon tient sur 456 px de haut, mais se
        # separe naturellement en « especes et attaques » a gauche et « objets »
        # a droite.
        [int]$FromX = -100000,
        [int]$ToX = 100000,
        [string]$TitleFr = "",
        [string]$TitleEn = "",
        [System.Windows.Forms.Label]$TitleSource = $null,
        [System.Windows.Forms.Label]$SubtitleSource = $null,
        [int]$CardX = -1,
        [int]$CardY = -1,
        [int]$CardWidth = 0,
        [int]$PaddingBottom = 16
    )

    Initialize-PfControlLibrary

    $groupe = @()
    foreach ($c in @($Parent.Controls)) {
        if ($c -eq $SubtitleSource -or $c -eq $TitleSource) { continue }
        if ($c.Top -ge $FromY -and $c.Top -le $ToY -and
            $c.Left -ge $FromX -and $c.Left -le $ToX) { $groupe += $c }
    }
    if ($groupe.Count -eq 0) {
        return $null
    }

    $minY = ($groupe | Measure-Object -Property Top -Minimum).Minimum
    $minX = ($groupe | Measure-Object -Property Left -Minimum).Minimum
    $maxBas = 0
    $maxDroite = 0
    foreach ($c in $groupe) {
        $bas = $c.Top + $c.Height
        if ($bas -gt $maxBas) { $maxBas = $bas }
        $droite = $c.Left + $c.Width
        if ($droite -gt $maxDroite) { $maxDroite = $droite }
    }

    # Largeur calculee sur le contenu, pas figee. Une valeur en dur de 1098
    # laissait deborder de 12 px le bouton « Résumé build » de l'onglet
    # Generation, dont le contenu va jusqu'a 1110.
    $marge = 12
    if ($CardX -lt 0) { $CardX = [Math]::Max(6, $minX - $marge) }
    $largeurContenu = ($maxDroite - $minX) + ($marge * 2)
    # ClientSize de l'onglet n'est pas encore etabli quand le helper tourne :
    # il rapportait 200 px, ce qui donnait des cartes de 188. On ne s'y fie que
    # s'il est plausible, sinon on prend la largeur du contenu.
    $largeurDispo = $Parent.ClientSize.Width - ($CardX * 2)
    if ($largeurDispo -lt 400) { $largeurDispo = $largeurContenu }
    if ($CardWidth -le 0) { $CardWidth = [Math]::Min($largeurDispo, $largeurContenu) }

    $contenuHaut = if ($SubtitleSource) { 72 } else { 46 }
    $carte = New-Object PokeFeur.Ui.PfCard
    $carte.Location = New-Object System.Drawing.Point($CardX, $(if ($CardY -ge 0) { $CardY } else { [Math]::Max(8, $minY - $contenuHaut) }))
    $carte.Size = New-Object System.Drawing.Size($CardWidth, ($contenuHaut + ($maxBas - $minY) + $PaddingBottom))
    if ($TitleSource) { $TitleSource.Visible = $false }
    if ($SubtitleSource) { $SubtitleSource.Visible = $false }
    $script:PfCardRegistry += [pscustomobject]@{
        Card = $carte
        TitleSource = $TitleSource
        SubtitleSource = $SubtitleSource
        TitleFr = $TitleFr
        TitleEn = $TitleEn
    }
    $Parent.Controls.Add($carte)

    foreach ($c in $groupe) {
        $nx = $c.Left - $minX + $marge
        $ny = $c.Top - $minY + $contenuHaut
        $Parent.Controls.Remove($c)
        $c.Location = New-Object System.Drawing.Point($nx, $ny)
        $carte.Controls.Add($c)
    }

    return $carte
}

function Add-PfShell {
    <#
        Pose la coque autour de l'interface existante : barre de titre maison,
        rail de navigation, et masquage du bandeau d'onglets.

        Principe : on ne deplace AUCUN controle un par un. Tout ce qui etait
        pose sur le formulaire est reparente en bloc dans un panneau de contenu,
        donc chaque coordonnee existante reste valable telle quelle. C'est ce
        qui rend l'operation sure sur 265 controles places en dur.
    #>
    param(
        [System.Windows.Forms.Form]$Form,
        [System.Windows.Forms.TabControl]$Tabs
    )

    Initialize-PfControlLibrary
    $railWidth = 248
    $barHeight = 40
    $oldWidth = $Form.ClientSize.Width
    $oldHeight = $Form.ClientSize.Height

    # 1. Panneau de contenu : recoit tel quel tout ce qui etait sur le formulaire.
    $contentHost = New-Object System.Windows.Forms.Panel
    $contentHost.Location = New-Object System.Drawing.Point($railWidth, $barHeight)
    $contentHost.Size = New-Object System.Drawing.Size($oldWidth, $oldHeight)
    $contentHost.BackColor = [PokeFeur.Ui.PfTheme]::Canvas

    $existing = @($Form.Controls)
    foreach ($c in $existing) {
        $Form.Controls.Remove($c)
        $contentHost.Controls.Add($c)
    }

    # La fenetre voulue fait 1412 x 1021. Elle tient sur un 1920 x 1080 avec
    # onze pixels de marge, et pas du tout sur un portable 1366 x 768 ou a 125 %
    # de mise a l'echelle. Comme elle est sans bordure et non redimensionnable,
    # ce qui depasse serait DEFINITIVEMENT inatteignable : ni redimensionnement,
    # ni deplacement complet dans l'ecran.
    #
    # On la borne donc a la zone de travail, et le panneau de contenu defile.
    # Personne ne perd d'option parce que son ecran est plus petit.
    $voulueW = $oldWidth + $railWidth
    $voulueH = $oldHeight + $barHeight
    $zone = [System.Windows.Forms.Screen]::FromPoint([System.Windows.Forms.Cursor]::Position).WorkingArea
    $finaleW = [Math]::Min($voulueW, $zone.Width)
    $finaleH = [Math]::Min($voulueH, $zone.Height)

    $contentHost.AutoScroll = $true
    $contentHost.Size = New-Object System.Drawing.Size(($finaleW - $railWidth), ($finaleH - $barHeight))
    $contentHost.Anchor = 'Top,Left,Right,Bottom'

    $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $Form.ClientSize = New-Object System.Drawing.Size($finaleW, $finaleH)
    $Form.MinimumSize = New-Object System.Drawing.Size([Math]::Min(900, $finaleW), [Math]::Min(600, $finaleH))
    $Form.MaximumSize = New-Object System.Drawing.Size($voulueW, $voulueH)
    $Form.Controls.Add($contentHost)

    # 2. Barre de titre dessinee, en remplacement de celle de Windows.
    $bar = New-Object PokeFeur.Ui.PfTitleBar
    $bar.Location = New-Object System.Drawing.Point(0, 0)
    $bar.Size = New-Object System.Drawing.Size($Form.ClientSize.Width, $barHeight)
    $bar.Anchor = 'Top,Left,Right'
    $bar.Caption = $Form.Text
    $Form.Controls.Add($bar)

    # 3. Rail de navigation, construit a partir des onglets reels.
    # Le rail commence SOUS la barre de titre : a y=0 sa marque passait
    # derriere elle et se retrouvait tronquee.
    $rail = New-Object PokeFeur.Ui.PfNavRail
    $rail.Location = New-Object System.Drawing.Point(0, $barHeight)
    $rail.Size = New-Object System.Drawing.Size($railWidth, ($Form.ClientSize.Height - $barHeight))
    $rail.Anchor = 'Top,Left,Bottom'
    $rail.Brand = "PokeFeur"
    $glyphs = @(
        [PokeFeur.Ui.PfGlyph]::Home,   [PokeFeur.Ui.PfGlyph]::People,
        [PokeFeur.Ui.PfGlyph]::Heart,  [PokeFeur.Ui.PfGlyph]::Swap,
        [PokeFeur.Ui.PfGlyph]::Gift,   [PokeFeur.Ui.PfGlyph]::Globe,
        [PokeFeur.Ui.PfGlyph]::Settings, [PokeFeur.Ui.PfGlyph]::Help,
        [PokeFeur.Ui.PfGlyph]::Reset
    )
    for ($i = 0; $i -lt $Tabs.TabPages.Count; $i++) {
        $glyph = if ($i -lt $glyphs.Count) { $glyphs[$i] } else { [PokeFeur.Ui.PfGlyph]::ChevronRight }
        # Les six premiers onglets reecrivent le ROMFS ; les suivants pilotent
        # le module ou l'entretien. Le rail rend cette frontiere visible.
        $group = if ($script:UiLanguage -eq "en") {
            if ($i -lt 6) { "Randomization" } else { "Module and upkeep" }
        } else {
            if ($i -lt 6) { "Randomisation" } else { "Module et entretien" }
        }
        $rail.Items.Add((New-Object PokeFeur.Ui.PfNavItem($glyph, [string]$Tabs.TabPages[$i].Text, $group)))
    }
    $rail.SelectedIndex = $Tabs.SelectedIndex
    $script:PfNavRail = $rail
    $script:PfTabs = $Tabs
    $rail.Add_SelectedIndexChanged({
        if ($script:PfTabs -and $script:PfNavRail) {
            $script:PfTabs.SelectedIndex = $script:PfNavRail.SelectedIndex
            if ($script:PfPageTitle) {
                $script:PfPageTitle.Text = [string]$script:PfTabs.TabPages[$script:PfTabs.SelectedIndex].Text
            }
        }
    })
    $Form.Controls.Add($rail)
    $rail.BringToFront()
    $bar.BringToFront()

    # 3bis. La marque vit desormais dans le rail : la garder aussi en haut du
    #       contenu ferait doublon. On la remplace par le titre de la page
    #       courante, qui manquait.
    $pageTitle = $null
    foreach ($c in $contentHost.Controls) {
        $tag = [string]$c.Tag
        if ($tag -eq "BrandPoke") {
            $c.Visible = $false
        } elseif ($tag -eq "BrandFeur") {
            $c.Visible = $false
        } elseif ($tag -eq "HeroSub") {
            $c.Location = New-Object System.Drawing.Point(24, 38)
            $c.Size = New-Object System.Drawing.Size(900, 20)
        }
    }
    $pageTitle = New-Object System.Windows.Forms.Label
    $pageTitle.Name = "PfPageTitle"
    $pageTitle.AutoSize = $false
    $pageTitle.Location = New-Object System.Drawing.Point(24, 10)
    $pageTitle.Size = New-Object System.Drawing.Size(700, 28)
    $pageTitle.Font = [PokeFeur.Ui.PfFont]::Title
    $pageTitle.ForeColor = [PokeFeur.Ui.PfTheme]::Text
    $pageTitle.BackColor = [PokeFeur.Ui.PfTheme]::Card
    $pageTitle.Text = [string]$Tabs.TabPages[$Tabs.SelectedIndex].Text
    $contentHost.Controls.Add($pageTitle)
    $pageTitle.BringToFront()
    $script:PfPageTitle = $pageTitle

    # 4. Masquer le bandeau d'onglets : le rail le remplace, en afficher deux
    #    serait deux navigations pour une seule chose. WinForms ne sait pas
    #    cacher ce bandeau, on decale donc le TabControl dans un panneau qui le
    #    rogne.
    # Deplacer un TabControl d'un parent a l'autre recree son handle et perd la
    # page selectionnee : le titre affichait « Nettoyage » alors que le rail
    # montrait « Generation ». On memorise l'index et on le restaure.
    $selectedTab = $Tabs.SelectedIndex
    $stripHeight = $Tabs.ItemSize.Height + 4
    $tabsParent = $Tabs.Parent
    $tabsLocation = $Tabs.Location
    $tabsSize = $Tabs.Size
    $clip = New-Object System.Windows.Forms.Panel
    # Nomme : le TabControl deborde volontairement de ce panneau, et les tests
    # de disposition doivent pouvoir distinguer ce debordement voulu d'un bug.
    $clip.Name = "PfTabClip"
    $clip.Location = $tabsLocation
    # Le panneau garde la taille D'ORIGINE du TabControl, et c'est le TabControl
    # qui grandit d'autant qu'il remonte. Le raccourcir de la hauteur du bandeau
    # rognait 38 px de contenu en bas de chaque onglet : cinq controles des
    # onglets Pokemon et Confort sortaient de la zone visible.
    $clip.Size = $tabsSize
    $clip.BackColor = [PokeFeur.Ui.PfTheme]::Canvas
    $tabsParent.Controls.Remove($Tabs)
    $Tabs.Location = New-Object System.Drawing.Point(0, (-1 * $stripHeight))
    $Tabs.Size = New-Object System.Drawing.Size($tabsSize.Width, ($tabsSize.Height + $stripHeight))
    $clip.Controls.Add($Tabs)
    $tabsParent.Controls.Add($clip)
    if ($selectedTab -ge 0 -and $selectedTab -lt $Tabs.TabPages.Count) {
        $Tabs.SelectedIndex = $selectedTab
    }

    # 5. Coins arrondis et barre sombre au niveau du gestionnaire de fenetres.
    try {
        [PokeFeur.Ui.NativeMethods]::ApplyWindowChrome($Form.Handle, ([PokeFeur.Ui.PfTheme]::Dark))
    } catch {
    }

    # Titre et rail suivent l'evenement du TabControl. Memoriser puis
    # restaurer l'index ne suffisait pas : la selection etait reecrite plus tard
    # et le titre affichait « Nettoyage » alors que le rail montrait
    # « Generation ». Une synchronisation par evenement ne peut pas deriver.
    $Tabs.Add_SelectedIndexChanged({
        if (-not $script:PfTabs) { return }
        $index = $script:PfTabs.SelectedIndex
        if ($index -lt 0 -or $index -ge $script:PfTabs.TabPages.Count) { return }
        if ($script:PfPageTitle) {
            $script:PfPageTitle.Text = [string]$script:PfTabs.TabPages[$index].Text
        }
        if ($script:PfNavRail -and $script:PfNavRail.SelectedIndex -ne $index) {
            $script:PfNavRail.SelectedIndex = $index
        }
    })
    $Tabs.SelectedIndex = 0
    $rail.SelectedIndex = 0
    if ($Tabs.TabPages.Count -gt 0) {
        $pageTitle.Text = [string]$Tabs.TabPages[0].Text
    }

    Update-PfRailLabels
    # Le reparentage recree les handles : sans invalidation explicite, des
    # enfants restent noirs jusqu'a la premiere interaction.
    $Form.Invalidate($true)
}

function Show-Gui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Initialize-PfControlLibrary
    if ((Get-NormalizedGuiTheme -Theme $GuiTheme) -eq "Dark") {
        [PokeFeur.Ui.PfTheme]::UseDark()
    } else {
        [PokeFeur.Ui.PfTheme]::UseLight()
    }

    $script:UiLanguage = if (([string]$UiLanguage).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $script:GuiTheme = Get-NormalizedGuiTheme -Theme $GuiTheme

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PokeFeur Randomizer SWSH $AppVersion"
    $form.ClientSize = New-Object System.Drawing.Size(1164, 980)
    $form.MinimumSize = New-Object System.Drawing.Size(1180, 1020)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    $form.StartPosition = "CenterScreen"
    $form.Font = New-GuiFont -Size 9.5
    Enable-GuiDoubleBuffer -Control $form
    Add-PokeFeurBackground -Form $form

    $controls = @{}
    $initialGameVersion = Get-NormalizedGameVersionSelection -Value $GameVersion
    if ($initialGameVersion -eq "Auto") {
        $initialGameVersion = "Sword"
    }
    $initialSourceRomfs = if (-not [string]::IsNullOrWhiteSpace($SourceRomfs)) {
        $SourceRomfs
    } else {
        Get-ExistingDefaultPathOrEmpty -Path (Get-DefaultSourceRomfsPath -GameVersion $initialGameVersion)
    }
    $initialSourceExefs = if (-not [string]::IsNullOrWhiteSpace($SourceExefs)) {
        $SourceExefs
    } else {
        ""
    }
    $initialOutputRomfs = if (-not [string]::IsNullOrWhiteSpace($OutputRomfs)) { $OutputRomfs } else { Get-DefaultOutputRomfsPath -GameVersion $initialGameVersion }

    $headerPanel = New-GuiChromePanel -X 0 -Y 0 -Width 1164 -Height 62 -Tag "HeaderPanel"
    $form.Controls.Add($headerPanel)
    $heroPanel = New-GuiChromePanel -X 18 -Y 76 -Width 748 -Height 186 -Tag "ChromePanel"
    $form.Controls.Add($heroPanel)
    $versionPanel = New-GuiChromePanel -X 778 -Y 76 -Width 160 -Height 80 -Tag "ChromePanel"
    $form.Controls.Add($versionPanel)
    $actionPanel = New-GuiChromePanel -X 958 -Y 76 -Width 190 -Height 186 -Tag "ActionPanel"
    $form.Controls.Add($actionPanel)
    $headerPanel.SendToBack()
    $heroPanel.SendToBack()
    $versionPanel.SendToBack()
    $actionPanel.SendToBack()

    $brandPoke = New-Label -Text "Poke" -X 24 -Y 16 -Width 96
    $brandPoke.Size = New-Object System.Drawing.Size(96, 40)
    $brandPoke.Tag = "BrandPoke"
    $form.Controls.Add($brandPoke)
    $brandFeur = New-Label -Text "Feur" -X 116 -Y 16 -Width 88
    $brandFeur.Size = New-Object System.Drawing.Size(88, 40)
    $brandFeur.Tag = "BrandFeur"
    $form.Controls.Add($brandFeur)
    $heroSub = New-Label -Text "Randomizer Sword / Shield - ROMFS, ExLaunch, presets et installation émulateur" -X 218 -Y 24 -Width 740
    $heroSub.Tag = "HeroSub"
    $form.Controls.Add($heroSub)

    $sourceLabel = New-Label -Text "" -X 32 -Y 88
    $form.Controls.Add($sourceLabel)
    $sourceBox = New-TextBox -Controls $controls -Name "Source" -X 32 -Y 112 -Width 600 -Text $initialSourceRomfs
    $form.Controls.Add($sourceBox)
    $browseSource = New-Object PokeFeur.Ui.PfButton
    $browseSource.Location = New-Object System.Drawing.Point(642, 110)
    $browseSource.Size = New-Object System.Drawing.Size(100, 30)
    $form.Controls.Add($browseSource)

    $gameVersionLabel = New-Label -Text "" -X 790 -Y 88 -Width 120
    $form.Controls.Add($gameVersionLabel)
    $gameVersionCombo = New-ComboBox -Controls $controls -Name "GameVersion" -X 790 -Y 112 -Width 140
    Add-ComboBoxItem -Combo $gameVersionCombo -Label "Bouclier" -Value "Shield"
    Add-ComboBoxItem -Combo $gameVersionCombo -Label "Épée" -Value "Sword"
    $gameVersionCombo.DisplayMember = "Label"
    $gameVersionCombo.SelectedIndex = if ($initialGameVersion -eq "Sword") { 1 } else { 0 }
    $form.Controls.Add($gameVersionCombo)

    $outputLabel = New-Label -Text "" -X 32 -Y 150 -Width 260
    $form.Controls.Add($outputLabel)
    $outputBox = New-TextBox -Controls $controls -Name "Output" -X 32 -Y 174 -Width 280 -Text $initialOutputRomfs
    $form.Controls.Add($outputBox)
    $browseOutput = New-Object PokeFeur.Ui.PfButton
    $browseOutput.Location = New-Object System.Drawing.Point(322, 172)
    $browseOutput.Size = New-Object System.Drawing.Size(88, 30)
    $form.Controls.Add($browseOutput)

    $sourceExefsLabel = New-Label -Text "" -X 430 -Y 150 -Width 260
    $form.Controls.Add($sourceExefsLabel)
    $sourceExefsBox = New-TextBox -Controls $controls -Name "SourceExefs" -X 430 -Y 174 -Width 220 -Text $initialSourceExefs
    $form.Controls.Add($sourceExefsBox)
    $browseSourceExefs = New-Object PokeFeur.Ui.PfButton
    $browseSourceExefs.Location = New-Object System.Drawing.Point(660, 172)
    $browseSourceExefs.Size = New-Object System.Drawing.Size(82, 30)
    $form.Controls.Add($browseSourceExefs)

    # Largeur explicite : la valeur par defaut de 200 px depassait dans la
    # colonne « Langue du logiciel », qui commence a 176. Les libelles ont
    # un fond opaque, donc une boite trop large peut repeindre sa voisine.
    $seedLabel = New-Label -Text "" -X 32 -Y 212 -Width 140
    $form.Controls.Add($seedLabel)
    $seedBox = New-TextBox -Controls $controls -Name "Seed" -X 32 -Y 236 -Width 120 -Text "-1"
    $form.Controls.Add($seedBox)

    $uiLangLabel = New-Label -Text "" -X 176 -Y 212 -Width 160
    $form.Controls.Add($uiLangLabel)
    $uiLangCombo = New-ComboBox -Controls $controls -Name "UiLanguage" -X 176 -Y 236 -Width 150
    Add-ComboBoxItem -Combo $uiLangCombo -Label "Francais" -Value "fr"
    Add-ComboBoxItem -Combo $uiLangCombo -Label "English" -Value "en"
    $uiLangCombo.DisplayMember = "Label"
    $uiLangCombo.SelectedIndex = if ($script:UiLanguage -eq "en") { 1 } else { 0 }
    $form.Controls.Add($uiLangCombo)

    $reportLangLabel = New-Label -Text "" -X 352 -Y 212 -Width 170
    $form.Controls.Add($reportLangLabel)
    $reportLangCombo = New-ComboBox -Controls $controls -Name "ReportLanguage" -X 352 -Y 236 -Width 150
    Add-ComboBoxItem -Combo $reportLangCombo -Label "Francais" -Value "fr"
    Add-ComboBoxItem -Combo $reportLangCombo -Label "English" -Value "en"
    $reportLangCombo.DisplayMember = "Label"
    $reportLangCombo.SelectedIndex = if (([string]$ReportLanguage).ToLowerInvariant() -eq "en") { 1 } else { 0 }
    $form.Controls.Add($reportLangCombo)

    $themeLabel = New-Label -Text "" -X 528 -Y 212 -Width 120
    $form.Controls.Add($themeLabel)
    $themeCombo = New-ComboBox -Controls $controls -Name "GuiTheme" -X 528 -Y 236 -Width 130
    Add-ComboBoxItem -Combo $themeCombo -Label "Clair" -Value "Light"
    Add-ComboBoxItem -Combo $themeCombo -Label "Sombre" -Value "Dark"
    $themeCombo.DisplayMember = "Label"
    $themeCombo.SelectedIndex = if ($script:GuiTheme -eq "Dark") { 1 } else { 0 }
    $form.Controls.Add($themeCombo)

    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $browseSource.Add_Click({
        if ($folderDialog.ShowDialog() -eq "OK") {
            $selectedPath = $folderDialog.SelectedPath
            $selectedRoot = $selectedPath
            $romfsChild = Join-Path $selectedPath "romfs"
            if (Test-Path -LiteralPath $romfsChild) {
                $selectedPath = $romfsChild
            }
            $controls.Source.Text = $selectedPath
            $detectedVersion = Get-SourceGameVersion -RomfsRoot $selectedPath
            # Le dossier vient d'etre choisi : on aligne la version detectee et le
            # dossier de sortie, mais on garde le chemin source tel quel.
            $script:SuppressGameVersionPathReset = $true
            try {
                [void](Set-ComboValue -Combo $controls.GameVersion -Value $detectedVersion)
            } finally {
                $script:SuppressGameVersionPathReset = $false
            }
            $controls.Output.Text = Get-DefaultOutputRomfsPath -GameVersion $detectedVersion
        }
    })
    $browseSourceExefs.Add_Click({
        if ($folderDialog.ShowDialog() -eq "OK") {
            $selectedPath = $folderDialog.SelectedPath
            $exefsChild = Join-Path $selectedPath "exefs"
            if (Test-Path -LiteralPath (Join-Path $exefsChild "main.npdm")) {
                $selectedPath = $exefsChild
            }
            $controls.SourceExefs.Text = $selectedPath
        }
    })
    $browseOutput.Add_Click({
        if ($folderDialog.ShowDialog() -eq "OK") { $controls.Output.Text = $folderDialog.SelectedPath }
    })
    $controls.GameVersion.Add_SelectedIndexChanged({
        if ($script:SuppressGameVersionPathReset) {
            return
        }
        $selectedVersion = Get-ComboValue -Combo $controls.GameVersion
        $controls.Source.Text = Get-ExistingDefaultPathOrEmpty -Path (Get-DefaultSourceRomfsPath -GameVersion $selectedVersion)
        $controls.SourceExefs.Text = ""
        $controls.Output.Text = Get-DefaultOutputRomfsPath -GameVersion $selectedVersion
    })

    $runButton = New-Object PokeFeur.Ui.PfButton
    $runButton.Location = New-Object System.Drawing.Point(974, 92)
    $runButton.Size = New-Object System.Drawing.Size(160, 84)
    $runButton.Tag = "PrimaryButton"
    $runButton.Primary = $true
    $form.Controls.Add($runButton)

    $exportPresetButton = New-Object PokeFeur.Ui.PfButton
    $exportPresetButton.Location = New-Object System.Drawing.Point(974, 184)
    $exportPresetButton.Size = New-Object System.Drawing.Size(160, 28)
    $form.Controls.Add($exportPresetButton)

    $importPresetButton = New-Object PokeFeur.Ui.PfButton
    $importPresetButton.Location = New-Object System.Drawing.Point(974, 218)
    $importPresetButton.Size = New-Object System.Drawing.Size(160, 28)
    $form.Controls.Add($importPresetButton)

    function Bring-TopChromeToFront {
        foreach ($control in @(
            $brandPoke,
            $brandFeur,
            $heroSub,
            $sourceLabel,
            $sourceBox,
            $browseSource,
            $gameVersionLabel,
            $gameVersionCombo,
            $outputLabel,
            $outputBox,
            $browseOutput,
            $sourceExefsLabel,
            $sourceExefsBox,
            $browseSourceExefs,
            $seedLabel,
            $seedBox,
            $uiLangLabel,
            $uiLangCombo,
            $reportLangLabel,
            $reportLangCombo,
            $themeLabel,
            $themeCombo,
            $runButton,
            $exportPresetButton,
            $importPresetButton
        )) {
            if ($control) {
                $control.BringToFront()
            }
        }
    }

    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Location = New-Object System.Drawing.Point(18, 270)
    $tabs.Size = New-Object System.Drawing.Size(1130, 520)
    $tabs.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
    $tabs.SizeMode = [System.Windows.Forms.TabSizeMode]::Fixed
    $tabs.ItemSize = New-Object System.Drawing.Size(124, 34)
    # Bandeau d'onglets redessine : plus de boites bordees, un simple
    # soulignement d'accent sur l'onglet actif. C'est le detail qui trahissait
    # le plus l'origine WinForms.
    $tabs.Add_DrawItem({
        param($sender, $eventArgs)
        $palette = Get-GuiThemePalette -Theme $script:GuiTheme
        $isSelected = ($eventArgs.Index -eq $sender.SelectedIndex)
        $g = $eventArgs.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $backBrush = New-Object System.Drawing.SolidBrush($palette.TabHeader)
        $accentBrush = New-Object System.Drawing.SolidBrush($palette.Accent)
        try {
            $frame = New-Object System.Drawing.Rectangle(
                ($eventArgs.Bounds.X - 3), ($eventArgs.Bounds.Y - 3),
                ($eventArgs.Bounds.Width + 6), ($eventArgs.Bounds.Height + 6))
            $g.FillRectangle($backBrush, $frame)
            if ($isSelected) {
                $selBrush = New-Object System.Drawing.SolidBrush($palette.Panel)
                try { $g.FillRectangle($selBrush, $eventArgs.Bounds) } finally { $selBrush.Dispose() }
            }
            $textColor = if ($isSelected) { $palette.Text } else { $palette.MutedText }
            $font = [PokeFeur.Ui.PfFont]::Body
            if ($isSelected) { $font = [PokeFeur.Ui.PfFont]::BodyBold }
            $flags = [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter -bor [System.Windows.Forms.TextFormatFlags]::EndEllipsis
            [System.Windows.Forms.TextRenderer]::DrawText($g, $sender.TabPages[$eventArgs.Index].Text, $font, $eventArgs.Bounds, $textColor, $flags)
            if ($isSelected) {
                $g.FillRectangle($accentBrush, ($eventArgs.Bounds.Left + 14), ($eventArgs.Bounds.Bottom - 3), ($eventArgs.Bounds.Width - 28), 2)
            }
        } finally {
            $backBrush.Dispose()
            $accentBrush.Dispose()
        }
    })
    $form.Controls.Add($tabs)

    $generalTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($generalTab)

    $trainerTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($trainerTab)

    $pokemonTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($pokemonTab)

    $evoTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($evoTab)

    $giftTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($giftTab)

    $encounterTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($encounterTab)

    $qolTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($qolTab)

    $helpTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($helpTab)

    $resetTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($resetTab)

    $generalInfoLabels = @()
    for ($i = 0; $i -lt 7; $i++) {
        $generalInfoLabel = New-Label -Text "" -X 18 -Y (18 + (25 * $i)) -Width 1060
        $generalInfoLabel.ForeColor = (Get-GuiThemePalette -Theme $script:GuiTheme).MutedText
        $generalInfoLabels += $generalInfoLabel
        $generalTab.Controls.Add($generalInfoLabel)
    }

    function Add-HiddenRemovedBuildOption {
        param(
            [System.Windows.Forms.Control]$Parent,
            [System.Collections.Hashtable]$Controls,
            [string]$Name
        )

        $hidden = New-CheckBox -Controls $Controls -Name $Name -Text "" -X 0 -Y 0 -Width 1 -Checked $false
        $hidden.Visible = $false
        $hidden.Enabled = $false
        $Parent.Controls.Add($hidden)
    }

    function Disable-RemovedBuildOptions {
        param([System.Collections.Hashtable]$Controls)

        foreach ($name in @(
            "EarlyBike",
            "DynamicExpLevelCap",
            "StrictBossMaxLevelCap",
            "MainStorySoftLevelCap",
            "StoryMajorBattleOrderLevelCap",
            "OverworldModelSafeEncounters",
            # Sans cette ligne, un preset deja exporte avec ModUnderworld = true
            # rallumerait l'option alors qu'elle n'apparait plus nulle part :
            # active sans le montrer, exactement le defaut que le projet traque.
            "ModUnderworld"
        )) {
            if ($Controls.ContainsKey($name)) {
                $Controls[$name].Checked = $false
                $Controls[$name].Visible = $false
                $Controls[$name].Enabled = $false
            }
        }
    }

    foreach ($removedOptionName in @(
        "EarlyBike",
        "DynamicExpLevelCap",
        "StrictBossMaxLevelCap",
        "MainStorySoftLevelCap",
        "StoryMajorBattleOrderLevelCap"
    )) {
        Add-HiddenRemovedBuildOption -Parent $generalTab -Controls $controls -Name $removedOptionName
    }

    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "DisableExpShare" -Text "" -X 18 -Y 202 -Width 520 -Checked $false))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "GymLeagueStoryLevelCap" -Text "" -X 18 -Y 232 -Width 860 -Checked $false))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "RuntimePcControls" -Text "" -X 18 -Y 262 -Width 520 -Checked $RuntimePcControls))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "WriteInstallationPackage" -Text "" -X 560 -Y 202 -Width 550 -Checked ([bool]$WriteInstallationPackage)))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "StrictDataFiles" -Text "" -X 560 -Y 262 -Width 550 -Checked ([bool]$StrictDataFiles)))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "AutoInstallToEden" -Text "" -X 18 -Y 292 -Width 390 -Checked ([bool]$AutoInstallToEden)))
    $edenModNameLabel = New-Label -Text "" -X 430 -Y 294 -Width 150
    $generalTab.Controls.Add($edenModNameLabel)
    $edenModNameBox = New-TextBox -Controls $controls -Name "EdenModName" -X 590 -Y 290 -Width 220 -Text $EdenModName
    $generalTab.Controls.Add($edenModNameBox)
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "InstallToRyujinx" -Text "" -X 18 -Y 324 -Width 300 -Checked $InstallToRyujinx))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "ExportEncounterZoneReport" -Text "JSON zones rencontres" -X 330 -Y 324 -Width 300 -Checked ([bool]$ExportEncounterZoneReport)))
    $validateBuildButton = New-Object PokeFeur.Ui.PfButton
    $validateBuildButton.Location = New-Object System.Drawing.Point(18, 360)
    $validateBuildButton.Size = New-Object System.Drawing.Size(126, 36)
    $generalTab.Controls.Add($validateBuildButton)
    $buildSummaryButton = New-Object PokeFeur.Ui.PfButton
    $buildSummaryButton.Location = New-Object System.Drawing.Point(154, 360)
    $buildSummaryButton.Size = New-Object System.Drawing.Size(126, 36)
    $generalTab.Controls.Add($buildSummaryButton)
    Disable-RemovedBuildOptions -Controls $controls

    Initialize-PfControlLibrary
    $helpBox = New-Object PokeFeur.Ui.PfTextBox
    $helpBox.Multiline = $true
    $helpBox.ReadOnly = $true
    $helpBox.ScrollBars = "Vertical"
    $helpBox.Location = New-Object System.Drawing.Point(18, 18)
    $helpBox.Size = New-Object System.Drawing.Size(1092, 448)
    # Le blanc systeme etait ecrit en dur ici, vestige de l epoque sans
    # theme. PfTextBox applique desormais la palette du theme courant.
    $helpTab.Controls.Add($helpBox)

    $resetInfoLabel = New-Label -Text "" -X 18 -Y 18 -Width 860
    $resetTab.Controls.Add($resetInfoLabel)
    $resetTab.Controls.Add((New-CheckBox -Controls $controls -Name "ResetInstallToRyujinx" -Text "Ryujinx" -X 18 -Y 56 -Width 220 -Checked $InstallToRyujinx))
    $resetButton = New-Object PokeFeur.Ui.PfButton
    $resetButton.Location = New-Object System.Drawing.Point(18, 148)
    $resetButton.Size = New-Object System.Drawing.Size(240, 34)
    $resetTab.Controls.Add($resetButton)
    Initialize-PfControlLibrary
    $resetStatusBox = New-Object PokeFeur.Ui.PfTextBox
    $resetStatusBox.Multiline = $true
    $resetStatusBox.ReadOnly = $true
    $resetStatusBox.ScrollBars = "Vertical"
    $resetStatusBox.Location = New-Object System.Drawing.Point(18, 232)
    $resetStatusBox.Size = New-Object System.Drawing.Size(892, 240)
    # Le blanc systeme etait ecrit en dur ici, vestige de l epoque sans
    # theme. PfTextBox applique desormais la palette du theme courant.
    $resetTab.Controls.Add($resetStatusBox)

    $trainerSpeciesLabel = New-Label -Text "" -X 18 -Y 18 -Width 220
    $trainerTab.Controls.Add($trainerSpeciesLabel)
    $trainerSpeciesCombo = New-ComboBox -Controls $controls -Name "TrainerSpeciesMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $trainerSpeciesCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $trainerSpeciesCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $trainerSpeciesCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerSpeciesCombo.DisplayMember = "Label"
    $trainerSpeciesCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerSpeciesCombo)

    $trainerMovesLabel = New-Label -Text "" -X 270 -Y 18 -Width 180
    $trainerTab.Controls.Add($trainerMovesLabel)
    $trainerMoveCombo = New-ComboBox -Controls $controls -Name "TrainerMoveMode" -X 270 -Y 42
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "4 attaques aleatoires" -Value "Random4"
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "Attaques naturelles au niveau" -Value "LastLevelUp4"
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "Strategique Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "Smogon + anciennes gens" -Value "SmogonLegacy"
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerMoveCombo.DisplayMember = "Label"
    $trainerMoveCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerMoveCombo)

    $trainerSmogonMoveFallbackLabel = New-Label -Text "" -X 270 -Y 68 -Width 196
    $trainerTab.Controls.Add($trainerSmogonMoveFallbackLabel)
    $trainerSmogonMoveFallbackCombo = New-ComboBox -Controls $controls -Name "TrainerSmogonMoveFallbackMode" -X 472 -Y 66 -Width 240
    Add-ComboBoxItem -Combo $trainerSmogonMoveFallbackCombo -Label "Backup niveau" -Value "LastLevelUp4"
    Add-ComboBoxItem -Combo $trainerSmogonMoveFallbackCombo -Label "Backup random" -Value "Random4"
    Add-ComboBoxItem -Combo $trainerSmogonMoveFallbackCombo -Label "Backup vanilla" -Value "Unchanged"
    $trainerSmogonMoveFallbackCombo.DisplayMember = "Label"
    $trainerSmogonMoveFallbackCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerSmogonMoveFallbackCombo)

    $trainerItemsLabel = New-Label -Text "" -X 522 -Y 18 -Width 220
    $trainerTab.Controls.Add($trainerItemsLabel)
    $trainerItemCombo = New-ComboBox -Controls $controls -Name "TrainerItemMode" -X 522 -Y 42
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Random si objet déjà présent" -Value "RandomWhenPresent"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Objet random sur tous" -Value "ForceAll"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Strategique Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Smogon + anciennes gens" -Value "SmogonLegacy"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Supprimer tous les objets" -Value "RemoveAll"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerItemCombo.DisplayMember = "Label"
    $trainerItemCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerItemCombo)

    $trainerItemPoolLabel = New-Label -Text "" -X 774 -Y 18 -Width 180
    $trainerTab.Controls.Add($trainerItemPoolLabel)
    $trainerItemPoolCombo = New-ComboBox -Controls $controls -Name "TrainerItemPoolMode" -X 774 -Y 42 -Width 220
    Add-ComboBoxItem -Combo $trainerItemPoolCombo -Label "Pool combat (objets utiles)" -Value "Battle"
    Add-ComboBoxItem -Combo $trainerItemPoolCombo -Label "Pool large safe (chaotique)" -Value "FullRandom"
    $trainerItemPoolCombo.DisplayMember = "Label"
    $trainerItemPoolCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerItemPoolCombo)

    $trainerAbilityLabel = New-Label -Text "" -X 18 -Y 92 -Width 230
    $trainerTab.Controls.Add($trainerAbilityLabel)
    $trainerAbilityCombo = New-ComboBox -Controls $controls -Name "TrainerAbilityMode" -X 18 -Y 116
    Add-ComboBoxItem -Combo $trainerAbilityCombo -Label "Randomiser le slot de talent" -Value "RandomSlot"
    Add-ComboBoxItem -Combo $trainerAbilityCombo -Label "Strategique Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerAbilityCombo -Label "Smogon + anciennes gens" -Value "SmogonLegacy"
    Add-ComboBoxItem -Combo $trainerAbilityCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerAbilityCombo.DisplayMember = "Label"
    $trainerAbilityCombo.SelectedIndex = 1
    $trainerTab.Controls.Add($trainerAbilityCombo)

    $trainerIvLabel = New-Label -Text "" -X 270 -Y 92 -Width 120
    $trainerTab.Controls.Add($trainerIvLabel)
    $trainerIvCombo = New-ComboBox -Controls $controls -Name "TrainerIVMode" -X 270 -Y 116
    Add-ComboBoxItem -Combo $trainerIvCombo -Label "31 partout" -Value "Max31"
    Add-ComboBoxItem -Combo $trainerIvCombo -Label "Aleatoire" -Value "Random"
    Add-ComboBoxItem -Combo $trainerIvCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerIvCombo.DisplayMember = "Label"
    $trainerIvCombo.SelectedIndex = 2
    $trainerTab.Controls.Add($trainerIvCombo)

    $trainerEvLabel = New-Label -Text "" -X 522 -Y 92 -Width 120
    $trainerTab.Controls.Add($trainerEvLabel)
    $trainerEvCombo = New-ComboBox -Controls $controls -Name "TrainerEVMode" -X 522 -Y 116
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "EV strategiques Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "EV Smogon + anciennes gens" -Value "SmogonLegacy"
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "EV legaux aleatoires" -Value "RandomLegal"
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "Mettre les EV à zéro" -Value "Zero"
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerEvCombo.DisplayMember = "Label"
    $trainerEvCombo.SelectedIndex = 3
    $trainerTab.Controls.Add($trainerEvCombo)

    $trainerAddedSlotSpeciesLabel = New-Label -Text "" -X 774 -Y 92 -Width 220
    $trainerTab.Controls.Add($trainerAddedSlotSpeciesLabel)
    $trainerAddedSlotSpeciesCombo = New-ComboBox -Controls $controls -Name "TrainerAddedSlotSpeciesMode" -X 774 -Y 116 -Width 220
    Add-ComboBoxItem -Combo $trainerAddedSlotSpeciesCombo -Label "Slots ajoutes: random complet" -Value "Random"
    Add-ComboBoxItem -Combo $trainerAddedSlotSpeciesCombo -Label "Slots ajoutes: BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $trainerAddedSlotSpeciesCombo -Label "Slots ajoutés: même type" -Value "SameTypeRandom"
    Add-ComboBoxItem -Combo $trainerAddedSlotSpeciesCombo -Label "Slots ajoutés: même type + BST" -Value "SameTypeBST"
    $trainerAddedSlotSpeciesCombo.DisplayMember = "Label"
    $trainerAddedSlotSpeciesCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerAddedSlotSpeciesCombo)

    $trainerDuplicateModeLabel = New-Label -Text "" -X 774 -Y 166 -Width 220
    $trainerTab.Controls.Add($trainerDuplicateModeLabel)
    $trainerDuplicateModeCombo = New-ComboBox -Controls $controls -Name "TrainerDuplicateMode" -X 774 -Y 190 -Width 220
    Add-ComboBoxItem -Combo $trainerDuplicateModeCombo -Label "Bloquer les doublons" -Value "NoDuplicates"
    Add-ComboBoxItem -Combo $trainerDuplicateModeCombo -Label "Random normal" -Value "Normal"
    $trainerDuplicateModeCombo.DisplayMember = "Label"
    $trainerDuplicateModeCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerDuplicateModeCombo)

    $bossTeamsScopeLabel = New-Label -Text "" -X 774 -Y 218 -Width 220
    $trainerTab.Controls.Add($bossTeamsScopeLabel)
    $bossTeamsScopeCombo = New-ComboBox -Controls $controls -Name "BossTeamsToSixScope" -X 774 -Y 242 -Width 220
    Add-ComboBoxItem -Combo $bossTeamsScopeCombo -Label "Boss importants" -Value "MajorBosses"
    Add-ComboBoxItem -Combo $bossTeamsScopeCombo -Label "Arènes + ligue uniquement" -Value "GymLeague"
    $bossTeamsScopeCombo.DisplayMember = "Label"
    $bossTeamsScopeCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($bossTeamsScopeCombo)

    $trainerLevelLabel = New-Label -Text "" -X 18 -Y 166 -Width 190
    $trainerTab.Controls.Add($trainerLevelLabel)
    $trainerLevelBox = New-TextBox -Controls $controls -Name "TrainerLevelMultiplier" -X 18 -Y 190 -Width 100 -Text "1.0"
    $trainerTab.Controls.Add($trainerLevelBox)

    $trainerTeamMinLabel = New-Label -Text "" -X 214 -Y 166 -Width 110
    $trainerTab.Controls.Add($trainerTeamMinLabel)
    $trainerTeamMinBox = New-TextBox -Controls $controls -Name "TrainerTeamMin" -X 214 -Y 190 -Width 60 -Text "-1"
    $trainerTab.Controls.Add($trainerTeamMinBox)

    $trainerTeamMaxLabel = New-Label -Text "" -X 324 -Y 166 -Width 110
    $trainerTab.Controls.Add($trainerTeamMaxLabel)
    $trainerTeamMaxBox = New-TextBox -Controls $controls -Name "TrainerTeamMax" -X 324 -Y 190 -Width 60 -Text "-1"
    $trainerTab.Controls.Add($trainerTeamMaxBox)

    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceAllTeamsToSix" -Text "" -X 420 -Y 190 -Width 300 -Checked $false))
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceBossTeamsToSix" -Text "" -X 420 -Y 220 -Width 340 -Checked $false))
    # Rangee serree : le champ « multiplicateur des niveaux » finit a 214 et la
    # liste des natures commence a 228. Il reste 14 px, pas 22. On reduit la
    # hauteur du libelle plutot que de decaler tout le bloc en dessous, ce qui
    # provoquait une collision plus bas.
    $trainerNatureModeLabel = New-Label -Text "" -X 18 -Y 214 -Width 220 -Height 14
    $trainerTab.Controls.Add($trainerNatureModeLabel)
    $trainerNatureModeCombo = New-ComboBox -Controls $controls -Name "TrainerNatureMode" -X 18 -Y 228 -Width 220
    Add-ComboBoxItem -Combo $trainerNatureModeCombo -Label "Garder vanilla" -Value "Unchanged"
    Add-ComboBoxItem -Combo $trainerNatureModeCombo -Label "Nature aleatoire" -Value "Random"
    Add-ComboBoxItem -Combo $trainerNatureModeCombo -Label "Nature strategique Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerNatureModeCombo -Label "Nature Smogon + anciennes gens" -Value "SmogonLegacy"
    $trainerNatureModeCombo.DisplayMember = "Label"
    $trainerNatureModeCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerNatureModeCombo)
    $legacyNatureCheck = New-CheckBox -Controls $controls -Name "RandomizeTrainerNatures" -Text "" -X 18 -Y 228 -Width 280 -Checked $false
    $legacyNatureCheck.Visible = $false
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryTrainers" -Text "" -X 18 -Y 258 -Width 420 -Checked $false))
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "MaxTrainerAI" -Text "" -X 522 -Y 258 -Width 244 -Checked $false))

    $trainerBagLabel = New-Label -Text "" -X 18 -Y 488 -Width 220
    $trainerTab.Controls.Add($trainerBagLabel)
    $trainerBagCombo = New-ComboBox -Controls $controls -Name "TrainerBagItemMode" -X 244 -Y 484 -Width 240
    Add-ComboBoxItem -Combo $trainerBagCombo -Label "Inchangé (celui du jeu)" -Value "Unchanged"
    Add-ComboBoxItem -Combo $trainerBagCombo -Label "Sac vide (aucun soin)" -Value "None"
    Add-ComboBoxItem -Combo $trainerBagCombo -Label "Objets tirés au hasard" -Value "Random"
    $trainerBagCombo.DisplayMember = "Label"
    $trainerBagCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerBagCombo)
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "TrainerTypeThemed" -Text "" -X 270 -Y 286 -Width 230 -Checked $false))
    $trainerShinyLabel = New-Label -Text "" -X 18 -Y 292 -Width 220
    $trainerTab.Controls.Add($trainerShinyLabel)
    $trainerShinyBox = New-TextBox -Controls $controls -Name "TrainerShinyChancePercent" -X 18 -Y 316 -Width 80 -Text "0"
    $trainerTab.Controls.Add($trainerShinyBox)
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceTrainerFullyEvolved" -Text "" -X 154 -Y 316 -Width 330 -Checked $false))
    $trainerFullyEvolvedLevelLabel = New-Label -Text "" -X 510 -Y 292 -Width 240
    $trainerTab.Controls.Add($trainerFullyEvolvedLevelLabel)
    $trainerFullyEvolvedLevelBox = New-TextBox -Controls $controls -Name "TrainerFullyEvolvedLevel" -X 510 -Y 316 -Width 70 -Text "40"
    $trainerTab.Controls.Add($trainerFullyEvolvedLevelBox)
    $trainerDynamaxLevelLabel = New-Label -Text "" -X 18 -Y 360 -Width 220
    $trainerTab.Controls.Add($trainerDynamaxLevelLabel)
    $trainerDynamaxLevelCombo = New-ComboBox -Controls $controls -Name "TrainerDynamaxLevelMode" -X 18 -Y 384 -Width 300
    Add-ComboBoxItem -Combo $trainerDynamaxLevelCombo -Label "Ne pas changer" -Value "Unchanged"
    Add-ComboBoxItem -Combo $trainerDynamaxLevelCombo -Label "Niveau Dynamax 10" -Value "Max10"
    Add-ComboBoxItem -Combo $trainerDynamaxLevelCombo -Label "Niveau Dynamax aleatoire 0-10" -Value "Random0To10"
    $trainerDynamaxLevelCombo.DisplayMember = "Label"
    $trainerDynamaxLevelCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerDynamaxLevelCombo)
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceTrainerCanDynamax" -Text "" -X 340 -Y 386 -Width 430 -Checked $false))
    Initialize-PfControlLibrary
    $bossTargetsBox = New-Object PokeFeur.Ui.PfTextBox
    $bossTargetsBox.Multiline = $true
    $bossTargetsBox.ReadOnly = $true
    $bossTargetsBox.ScrollBars = "Vertical"
    # Le retour a la ligne etait desactive pour que la liste de boss tienne un
    # nom par ligne. Mais la boite affiche aussi des PHRASES - son titre, la
    # note de bas de liste, et le message qui s'affiche quand l'option est
    # decochee -, et celles-la etaient coupees net a 320 px : une boite de 162
    # px de haut ne montrait qu'une ligne tronquee. Les noms de dresseurs sont
    # courts et ne se replient pas ; les phrases, si.
    $bossTargetsBox.WordWrap = $true
    $bossTargetsBox.Location = New-Object System.Drawing.Point(790, 292)
    $bossTargetsBox.Size = New-Object System.Drawing.Size(320, 162)
    # Le blanc systeme etait ecrit en dur ici, vestige de l epoque sans
    # theme. PfTextBox applique desormais la palette du theme courant.
    $trainerTab.Controls.Add($bossTargetsBox)

    # --- Regles speciales de dresseurs -------------------------------------
    # Trois classes : Boss (arenes, Conseil 4, Maitre), Important (rivaux, chefs
    # d'equipe), Normal (le reste). Chaque classe peut recevoir des Pokemon en
    # plus, et une regle de composition peut viser une portee au choix.
    $trainerExtraPokemonLabel = New-Label -Text "" -X 18 -Y 420 -Width 152
    $trainerTab.Controls.Add($trainerExtraPokemonLabel)
    $trainerExtraBossLabel = New-Label -Text "" -X 176 -Y 420 -Width 46
    $trainerTab.Controls.Add($trainerExtraBossLabel)
    $trainerTab.Controls.Add((New-TextBox -Controls $controls -Name "TrainerExtraPokemonBoss" -X 224 -Y 416 -Width 40 -Text "0"))
    $trainerExtraImportantLabel = New-Label -Text "" -X 274 -Y 420 -Width 78
    $trainerTab.Controls.Add($trainerExtraImportantLabel)
    $trainerTab.Controls.Add((New-TextBox -Controls $controls -Name "TrainerExtraPokemonImportant" -X 354 -Y 416 -Width 40 -Text "0"))
    $trainerExtraRegularLabel = New-Label -Text "" -X 404 -Y 420 -Width 62
    $trainerTab.Controls.Add($trainerExtraRegularLabel)
    $trainerTab.Controls.Add((New-TextBox -Controls $controls -Name "TrainerExtraPokemonRegular" -X 468 -Y 416 -Width 40 -Text "0"))
    $diverseTypesLabel = New-Label -Text "" -X 528 -Y 420 -Width 120
    $trainerTab.Controls.Add($diverseTypesLabel)
    $diverseTypesCombo = New-ComboBox -Controls $controls -Name "TrainerForceDiverseTypes" -X 652 -Y 416 -Width 130
    Add-ComboBoxItem -Combo $diverseTypesCombo -Label "Désactivé" -Value "Off"
    Add-ComboBoxItem -Combo $diverseTypesCombo -Label "Arènes + Ligue" -Value "GymLeague"
    Add-ComboBoxItem -Combo $diverseTypesCombo -Label "Tous les boss" -Value "AllBosses"
    Add-ComboBoxItem -Combo $diverseTypesCombo -Label "Tout le monde" -Value "Everyone"
    $diverseTypesCombo.DisplayMember = "Label"
    $diverseTypesCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($diverseTypesCombo)

    $trainerSpecialRuleLabel = New-Label -Text "" -X 18 -Y 456 -Width 152
    $trainerTab.Controls.Add($trainerSpecialRuleLabel)
    $trainerSpecialRuleScopeCombo = New-ComboBox -Controls $controls -Name "TrainerSpecialRuleScope" -X 176 -Y 452 -Width 156
    Add-ComboBoxItem -Combo $trainerSpecialRuleScopeCombo -Label "Arènes + Ligue" -Value "GymLeague"
    Add-ComboBoxItem -Combo $trainerSpecialRuleScopeCombo -Label "Tous les boss" -Value "AllBosses"
    Add-ComboBoxItem -Combo $trainerSpecialRuleScopeCombo -Label "Tout le monde" -Value "Everyone"
    $trainerSpecialRuleScopeCombo.DisplayMember = "Label"
    $trainerSpecialRuleScopeCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerSpecialRuleScopeCombo)
    $trainerLegendaryPolicyCombo = New-ComboBox -Controls $controls -Name "TrainerLegendaryPolicy" -X 340 -Y 452 -Width 196
    Add-ComboBoxItem -Combo $trainerLegendaryPolicyCombo -Label "Ne rien imposer" -Value "Unchanged"
    Add-ComboBoxItem -Combo $trainerLegendaryPolicyCombo -Label "Aucun légendaire" -Value "None"
    Add-ComboBoxItem -Combo $trainerLegendaryPolicyCombo -Label "Un légendaire chacun" -Value "OneEach"
    Add-ComboBoxItem -Combo $trainerLegendaryPolicyCombo -Label "Que des légendaires" -Value "All"
    $trainerLegendaryPolicyCombo.DisplayMember = "Label"
    $trainerLegendaryPolicyCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerLegendaryPolicyCombo)
    $trainerMinBstLabel = New-Label -Text "" -X 546 -Y 456 -Width 96
    $trainerTab.Controls.Add($trainerMinBstLabel)
    $trainerTab.Controls.Add((New-TextBox -Controls $controls -Name "TrainerMinBaseStatTotal" -X 646 -Y 452 -Width 50 -Text "0"))

    $typeModeLabel = New-Label -Text "" -X 18 -Y 18 -Width 120
    $pokemonTab.Controls.Add($typeModeLabel)
    $typeModeCombo = New-ComboBox -Controls $controls -Name "TypeMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $typeModeCombo -Label "Randomiser les types" -Value "Random"
    Add-ComboBoxItem -Combo $typeModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $typeModeCombo.DisplayMember = "Label"
    $typeModeCombo.SelectedIndex = 1
    $pokemonTab.Controls.Add($typeModeCombo)

    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "TypesMonotypeOnly" -Text "" -X 258 -Y 44 -Width 300 -Checked $false))

    $abilityModeLabel = New-Label -Text "" -X 18 -Y 76 -Width 230
    $pokemonTab.Controls.Add($abilityModeLabel)
    $abilityModeCombo = New-ComboBox -Controls $controls -Name "AbilityMode" -X 18 -Y 100
    Add-ComboBoxItem -Combo $abilityModeCombo -Label "Randomiser les talents" -Value "Random"
    Add-ComboBoxItem -Combo $abilityModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $abilityModeCombo.DisplayMember = "Label"
    $abilityModeCombo.SelectedIndex = 1
    $pokemonTab.Controls.Add($abilityModeCombo)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowWonderGuard" -Text "" -X 258 -Y 102 -Width 300 -Checked $false))

    $statModeLabel = New-Label -Text "" -X 18 -Y 134 -Width 200
    $pokemonTab.Controls.Add($statModeLabel)
    $statModeCombo = New-ComboBox -Controls $controls -Name "StatMode" -X 18 -Y 158
    Add-ComboBoxItem -Combo $statModeCombo -Label "Melanger les 6 stats" -Value "Shuffle"
    Add-ComboBoxItem -Combo $statModeCombo -Label "Redistribuer le BST" -Value "Redistribute"
    Add-ComboBoxItem -Combo $statModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $statModeCombo.DisplayMember = "Label"
    $statModeCombo.SelectedIndex = 2
    $pokemonTab.Controls.Add($statModeCombo)

    $expYieldMultiplierLabel = New-Label -Text "" -X 18 -Y 380 -Width 250
    $pokemonTab.Controls.Add($expYieldMultiplierLabel)
    $expYieldMultiplierBox = New-TextBox -Controls $controls -Name "ExpYieldMultiplier" -X 18 -Y 404 -Width 80 -Text "1.0"
    $pokemonTab.Controls.Add($expYieldMultiplierBox)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceOneExpYield" -Text "" -X 112 -Y 406 -Width 330 -Checked $false))

    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMoveTypes" -Text "" -X 600 -Y 20 -Width 300 -Checked $false))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMovePower" -Text "" -X 600 -Y 92 -Width 230 -Checked $false))
    $movePowerMinLabel = New-Label -Text "" -X 840 -Y 88 -Width 120
    $pokemonTab.Controls.Add($movePowerMinLabel)
    $movePowerMinBox = New-TextBox -Controls $controls -Name "MovePowerMin" -X 840 -Y 110 -Width 70 -Text "20"
    $pokemonTab.Controls.Add($movePowerMinBox)
    $movePowerMaxLabel = New-Label -Text "" -X 966 -Y 88 -Width 120
    $pokemonTab.Controls.Add($movePowerMaxLabel)
    $movePowerMaxBox = New-TextBox -Controls $controls -Name "MovePowerMax" -X 966 -Y 110 -Width 70 -Text "150"
    $pokemonTab.Controls.Add($movePowerMaxBox)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMovePP" -Text "" -X 600 -Y 148 -Width 230 -Checked $false))
    $movePPMinLabel = New-Label -Text "" -X 840 -Y 144 -Width 120
    $pokemonTab.Controls.Add($movePPMinLabel)
    $movePPMinBox = New-TextBox -Controls $controls -Name "MovePPMin" -X 840 -Y 166 -Width 70 -Text "5"
    $pokemonTab.Controls.Add($movePPMinBox)
    $movePPMaxLabel = New-Label -Text "" -X 966 -Y 144 -Width 120
    $pokemonTab.Controls.Add($movePPMaxLabel)
    $movePPMaxBox = New-TextBox -Controls $controls -Name "MovePPMax" -X 966 -Y 166 -Width 70 -Text "40"
    $pokemonTab.Controls.Add($movePPMaxBox)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMoveAccuracy" -Text "" -X 600 -Y 204 -Width 230 -Checked $false))
    # Les libelles ont un fond OPAQUE : une boite trop large repeint le texte
    # de sa voisine, ce qui avait deja affiche « recision max ». Les colonnes
    # min et max sont donc espacees de 126 px pour des libelles de 120.
    $moveAccuracyMinLabel = New-Label -Text "" -X 840 -Y 200 -Width 120
    $pokemonTab.Controls.Add($moveAccuracyMinLabel)
    $moveAccuracyMinBox = New-TextBox -Controls $controls -Name "MoveAccuracyMin" -X 840 -Y 222 -Width 70 -Text "70"
    $pokemonTab.Controls.Add($moveAccuracyMinBox)
    $moveAccuracyMaxLabel = New-Label -Text "" -X 966 -Y 200 -Width 120
    $pokemonTab.Controls.Add($moveAccuracyMaxLabel)
    $moveAccuracyMaxBox = New-TextBox -Controls $controls -Name "MoveAccuracyMax" -X 966 -Y 222 -Width 70 -Text "100"
    $pokemonTab.Controls.Add($moveAccuracyMaxBox)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMoveCategory" -Text "" -X 600 -Y 50 -Width 300 -Checked $false))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizePickupItems" -Text "" -X 18 -Y 440 -Width 200 -Checked ([bool]$RandomizePickupItems)))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeShopItems" -Text "" -X 232 -Y 440 -Width 200 -Checked ([bool]$RandomizeShopItems)))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeTechnicalRecords" -Text "" -X 446 -Y 440 -Width 200 -Checked ([bool]$RandomizeTechnicalRecords)))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "FollowEvolutionsForTypes" -Text "" -X 18 -Y 196 -Width 480 -Checked ([bool]$FollowEvolutionsForTypes)))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "FollowEvolutionsForAbilities" -Text "" -X 18 -Y 226 -Width 480 -Checked ([bool]$FollowEvolutionsForAbilities)))

    # Range avec les autres proprietes d'espece, a droite des statistiques.
    $learnsetMoveLabel = New-Label -Text "" -X 258 -Y 138 -Width 170
    $pokemonTab.Controls.Add($learnsetMoveLabel)
    $learnsetMoveCombo = New-ComboBox -Controls $controls -Name "LearnsetMoveMode" -X 258 -Y 162 -Width 220
    Add-ComboBoxItem -Combo $learnsetMoveCombo -Label "Ne pas changer" -Value "Unchanged"
    Add-ComboBoxItem -Combo $learnsetMoveCombo -Label "Permuter entre espèces" -Value "Shuffle"
    Add-ComboBoxItem -Combo $learnsetMoveCombo -Label "Tirage aléatoire" -Value "Random"
    Add-ComboBoxItem -Combo $learnsetMoveCombo -Label "Tirage intégral (toutes les attaques)" -Value "FullRandom"
    $learnsetMoveCombo.DisplayMember = "Label"
    $learnsetMoveCombo.SelectedIndex = 0
    $pokemonTab.Controls.Add($learnsetMoveCombo)
    $shopPriceLabel = New-Label -Text "" -X 470 -Y 380 -Width 150
    $pokemonTab.Controls.Add($shopPriceLabel)
    $shopItemModeLabel = New-Label -Text "" -X 700 -Y 380 -Width 240
    $pokemonTab.Controls.Add($shopItemModeLabel)
    $shopItemModeCombo = New-ComboBox -Controls $controls -Name "ShopItemMode" -X 700 -Y 404 -Width 240
    Add-ComboBoxItem -Combo $shopItemModeCombo -Label "Même genre d'objet" -Value "SamePocket"
    Add-ComboBoxItem -Combo $shopItemModeCombo -Label "Tout ce que la boutique vend" -Value "FullRandom"
    $shopItemModeCombo.DisplayMember = "Label"
    $shopItemModeCombo.SelectedIndex = 0
    $pokemonTab.Controls.Add($shopItemModeCombo)

    $shopPriceCombo = New-ComboBox -Controls $controls -Name "ShopPriceMultiplier" -X 470 -Y 404 -Width 200
    Add-ComboBoxItem -Combo $shopPriceCombo -Label "Gratuit (x0)" -Value "0"
    Add-ComboBoxItem -Combo $shopPriceCombo -Label "Moitie prix (x0.5)" -Value "0.5"
    Add-ComboBoxItem -Combo $shopPriceCombo -Label "Prix normaux (x1)" -Value "1"
    Add-ComboBoxItem -Combo $shopPriceCombo -Label "Double (x2)" -Value "2"
    Add-ComboBoxItem -Combo $shopPriceCombo -Label "Tres cher (x5)" -Value "5"
    Add-ComboBoxItem -Combo $shopPriceCombo -Label "Aleatoire (100 - 5 000)" -Value "random:100:5000"
    Add-ComboBoxItem -Combo $shopPriceCombo -Label "Aleatoire (300 - 20 000)" -Value "random:300:20000"
    Add-ComboBoxItem -Combo $shopPriceCombo -Label "Aleatoire (1 - 999 999)" -Value "random:1:999999"
    $shopPriceCombo.DisplayMember = "Label"
    $shopPriceCombo.SelectedIndex = 2
    $pokemonTab.Controls.Add($shopPriceCombo)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeFieldItems" -Text "" -X 700 -Y 440 -Width 200 -Checked ([bool]$RandomizeFieldItems)))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeHiddenItems" -Text "" -X 700 -Y 470 -Width 200 -Checked ([bool]$RandomizeHiddenItems)))
    $fieldItemPoolCombo = New-ComboBox -Controls $controls -Name "FieldItemPoolMode" -X 914 -Y 468 -Width 180
    Add-ComboBoxItem -Combo $fieldItemPoolCombo -Label "Sans objets clés" -Value "Safe"
    Add-ComboBoxItem -Combo $fieldItemPoolCombo -Label "Tout, CT et DT incluses" -Value "All"
    $fieldItemPoolCombo.DisplayMember = "Label"
    $fieldItemPoolCombo.SelectedIndex = 0
    $pokemonTab.Controls.Add($fieldItemPoolCombo)

    $evoModeLabel = New-Label -Text "" -X 18 -Y 18 -Width 140
    $evoTab.Controls.Add($evoModeLabel)
    $evoModeCombo = New-ComboBox -Controls $controls -Name "EvolutionMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $evoModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $evoModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $evoModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $evoModeCombo.DisplayMember = "Label"
    $evoModeCombo.SelectedIndex = 2
    $evoTab.Controls.Add($evoModeCombo)
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryEvolutions" -Text "" -X 270 -Y 44 -Width 300 -Checked $false))
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "NormalizeFriendshipEvolutions" -Text "" -X 18 -Y 92 -Width 340 -Checked $false))
    $friendshipLevelLabel = New-Label -Text "" -X 370 -Y 92 -Width 120
    $evoTab.Controls.Add($friendshipLevelLabel)
    $friendshipLevelBox = New-TextBox -Controls $controls -Name "FriendshipEvolutionLevel" -X 370 -Y 116 -Width 70 -Text "30"
    $evoTab.Controls.Add($friendshipLevelBox)
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "NormalizeTradeEvolutions" -Text "" -X 18 -Y 154 -Width 340 -Checked $false))
    $tradeLevelLabelEvo = New-Label -Text "" -X 370 -Y 154 -Width 120
    $evoTab.Controls.Add($tradeLevelLabelEvo)
    $tradeLevelBox = New-TextBox -Controls $controls -Name "TradeEvolutionLevel" -X 370 -Y 178 -Width 70 -Text "37"
    $evoTab.Controls.Add($tradeLevelBox)
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "NormalizeSpecialEvolutions" -Text "" -X 18 -Y 216 -Width 420 -Checked $false))
    $specialLevelLabelEvo = New-Label -Text "" -X 470 -Y 216 -Width 140
    $evoTab.Controls.Add($specialLevelLabelEvo)
    $specialLevelBox = New-TextBox -Controls $controls -Name "SpecialEvolutionLevel" -X 470 -Y 240 -Width 70 -Text "36"
    $evoTab.Controls.Add($specialLevelBox)
    # Contraintes sur la cible tiree. Sans effet si le mode d'evolution reste
    # sur "Ne pas changer" : il n'y a alors aucun tirage a contraindre.
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "EvolutionForceGrowth" -Text "" -X 18 -Y 264 -Width 620 -Checked ([bool]$EvolutionForceGrowth)))
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "EvolutionSameType" -Text "" -X 18 -Y 300 -Width 620 -Checked ([bool]$EvolutionSameType)))
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "EvolutionLimitToThreeStages" -Text "" -X 18 -Y 336 -Width 620 -Checked ([bool]$EvolutionLimitToThreeStages)))

    # Y 376 tombait HORS de la carte « Contraintes sur les chaines » (260..340)
    # et se dessinait par-dessus son en-tete. On reste dans la plage, et la
    # carte est etendue plus bas pour l'accueillir.
    $evoMinBstLabel = New-Label -Text "" -X 660 -Y 268 -Width 250
    $evoTab.Controls.Add($evoMinBstLabel)
    $evoTab.Controls.Add((New-TextBox -Controls $controls -Name "EvolutionMinBstGain" -X 916 -Y 264 -Width 70 -Text ([string][int]$EvolutionMinBstGain)))

    $giftModeLabel = New-Label -Text "" -X 18 -Y 18 -Width 190
    $giftTab.Controls.Add($giftModeLabel)
    $giftModeCombo = New-ComboBox -Controls $controls -Name "GiftMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $giftModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $giftModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $giftModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $giftModeCombo.DisplayMember = "Label"
    $giftModeCombo.SelectedIndex = 2
    $giftTab.Controls.Add($giftModeCombo)

    $starterModeLabel = New-Label -Text "" -X 270 -Y 18 -Width 180
    $giftTab.Controls.Add($starterModeLabel)
    $starterModeCombo = New-ComboBox -Controls $controls -Name "StarterMode" -X 270 -Y 42
    Add-ComboBoxItem -Combo $starterModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $starterModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $starterModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $starterModeCombo.DisplayMember = "Label"
    $starterModeCombo.SelectedIndex = 2
    $giftTab.Controls.Add($starterModeCombo)

    $giftTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryGifts" -Text "" -X 522 -Y 44 -Width 340 -Checked $false))

    # Les OBJETS offerts par les PNJ, a cote des Pokemon offerts : meme geste du
    # joueur, meme endroit dans l'interface.
    $npcGiftItemLabel = New-Label -Text "" -X 880 -Y 18 -Width 210
    $giftTab.Controls.Add($npcGiftItemLabel)
    $npcGiftItemCombo = New-ComboBox -Controls $controls -Name "NpcGiftItemMode" -X 880 -Y 42 -Width 220
    Add-ComboBoxItem -Combo $npcGiftItemCombo -Label "Ne pas changer" -Value "Unchanged"
    Add-ComboBoxItem -Combo $npcGiftItemCombo -Label "Permuter entre PNJ" -Value "Shuffle"
    Add-ComboBoxItem -Combo $npcGiftItemCombo -Label "Tirage aléatoire" -Value "Random"
    $npcGiftItemCombo.DisplayMember = "Label"
    $npcGiftItemCombo.SelectedIndex = 0
    $giftTab.Controls.Add($npcGiftItemCombo)

    $manualStarterGroupLabel = New-Label -Text "" -X 18 -Y 90 -Width 1040 -Height 34
    $giftTab.Controls.Add($manualStarterGroupLabel)
    $starter1Label = New-Label -Text "" -X 18 -Y 126 -Width 60
    $giftTab.Controls.Add($starter1Label)
    $starter1Box = New-TextBox -Controls $controls -Name "Starter1" -X 18 -Y 150 -Width 180 -Text ""
    $giftTab.Controls.Add($starter1Box)
    $starter2Label = New-Label -Text "" -X 214 -Y 126 -Width 60
    $giftTab.Controls.Add($starter2Label)
    $starter2Box = New-TextBox -Controls $controls -Name "Starter2" -X 214 -Y 150 -Width 180 -Text ""
    $giftTab.Controls.Add($starter2Box)
    $starter3Label = New-Label -Text "" -X 410 -Y 126 -Width 60
    $giftTab.Controls.Add($starter3Label)
    $starter3Box = New-TextBox -Controls $controls -Name "Starter3" -X 410 -Y 150 -Width 180 -Text ""
    $giftTab.Controls.Add($starter3Box)
    $starterAutoComplete = New-SpeciesAutoCompleteSource
    foreach ($starterBox in @($starter1Box, $starter2Box, $starter3Box)) {
        $starterBox.AutoCompleteMode = "SuggestAppend"
        $starterBox.AutoCompleteSource = "CustomSource"
        $starterBox.AutoCompleteCustomSource = $starterAutoComplete
        $starterBox.Add_Leave({
            param($sender, $eventArgs)
            Complete-SpeciesTextBoxValue -TextBox $sender -Language $script:UiLanguage
        })
        $starterBox.Add_KeyDown({
            param($sender, $eventArgs)
            if ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                Complete-SpeciesTextBoxValue -TextBox $sender -Language $script:UiLanguage
                $eventArgs.SuppressKeyPress = $true
            }
        })
    }
    $giftTab.Controls.Add((New-CheckBox -Controls $controls -Name "PatchStarterRelatedTrainers" -Text "" -X 606 -Y 152 -Width 430 -Checked $true))

    $tradeModeLabel = New-Label -Text "" -X 18 -Y 196 -Width 160
    $giftTab.Controls.Add($tradeModeLabel)
    $tradeModeCombo = New-ComboBox -Controls $controls -Name "TradeMode" -X 18 -Y 220
    Add-ComboBoxItem -Combo $tradeModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $tradeModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $tradeModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $tradeModeCombo.DisplayMember = "Label"
    $tradeModeCombo.SelectedIndex = 2
    $giftTab.Controls.Add($tradeModeCombo)
    $giftTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryTrades" -Text "" -X 270 -Y 222 -Width 320 -Checked $false))
    $starterBstLabel = New-Label -Text "" -X 18 -Y 274 -Width 300
    $giftTab.Controls.Add($starterBstLabel)
    $giftTab.Controls.Add((New-TextBox -Controls $controls -Name "StarterMinBaseStatTotal" -X 324 -Y 270 -Width 60 -Text ([string][int]$StarterMinBaseStatTotal)))
    $starterBstSepLabel = New-Label -Text "-" -X 392 -Y 274 -Width 14
    $giftTab.Controls.Add($starterBstSepLabel)
    $giftTab.Controls.Add((New-TextBox -Controls $controls -Name "StarterMaxBaseStatTotal" -X 412 -Y 270 -Width 60 -Text ([string][int]$StarterMaxBaseStatTotal)))

    $staticModeLabel = New-Label -Text "" -X 18 -Y 18 -Width 220
    $encounterTab.Controls.Add($staticModeLabel)
    $staticEncounterCombo = New-ComboBox -Controls $controls -Name "StaticEncounterMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $staticEncounterCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $staticEncounterCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $staticEncounterCombo -Label "Ne pas changer" -Value "Unchanged"
    $staticEncounterCombo.DisplayMember = "Label"
    $staticEncounterCombo.SelectedIndex = 2
    $encounterTab.Controls.Add($staticEncounterCombo)
    $encounterTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryStaticEncounters" -Text "" -X 270 -Y 44 -Width 340 -Checked $false))
    $staticStableMappingLabel = New-Label -Text "" -X 18 -Y 74 -Width 220
    $encounterTab.Controls.Add($staticStableMappingLabel)
    $staticStableMappingCombo = New-ComboBox -Controls $controls -Name "StaticEncounterStableMapping" -X 270 -Y 70 -Width 170
    # "Vrai random build" a ete retire des DEUX listes de stabilite : la cle de
    # stabilite du mode "par slot" contient les coordonnees du slot, donc elle
    # n'est jamais rencontree deux fois et la table de correspondance ne sert
    # jamais. Mesure du 2026-09-08 sur data_table.gfpak : 16449 emplacements
    # modifies, empreintes (offset:espece) STRICTEMENT identiques entre les deux
    # modes. La valeur "Random" reste acceptee en ligne de commande et a
    # l'import d'un ancien preset, elle est simplement traitee comme "Slot".
    Add-ComboBoxItem -Combo $staticStableMappingCombo -Label "Par slot" -Value "Slot"
    Add-ComboBoxItem -Combo $staticStableMappingCombo -Label "Par espèce" -Value "Species"
    $staticStableMappingCombo.DisplayMember = "Label"
    $staticStableMappingCombo.SelectedIndex = 0
    $encounterTab.Controls.Add($staticStableMappingCombo)

    $grassModeLabel = New-Label -Text "" -X 18 -Y 126 -Width 220
    $encounterTab.Controls.Add($grassModeLabel)
    $grassEncounterCombo = New-ComboBox -Controls $controls -Name "GrassEncounterMode" -X 18 -Y 150
    Add-ComboBoxItem -Combo $grassEncounterCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $grassEncounterCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $grassEncounterCombo -Label "Ne pas changer" -Value "Unchanged"
    $grassEncounterCombo.DisplayMember = "Label"
    $grassEncounterCombo.SelectedIndex = 2
    $encounterTab.Controls.Add($grassEncounterCombo)
    $encounterTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryGrassEncounters" -Text "" -X 270 -Y 152 -Width 340 -Checked $false))
    $grassStableMappingLabel = New-Label -Text "" -X 18 -Y 182 -Width 220
    $encounterTab.Controls.Add($grassStableMappingLabel)
    $grassStableMappingCombo = New-ComboBox -Controls $controls -Name "GrassEncounterStableMapping" -X 270 -Y 178 -Width 170
    Add-ComboBoxItem -Combo $grassStableMappingCombo -Label "Par slot" -Value "Slot"
    Add-ComboBoxItem -Combo $grassStableMappingCombo -Label "Par espèce" -Value "Species"
    $grassStableMappingCombo.DisplayMember = "Label"
    $grassStableMappingCombo.SelectedIndex = 0
    $encounterTab.Controls.Add($grassStableMappingCombo)

    $visibleBehaviorLabel = New-Label -Text "" -X 18 -Y 226 -Width 250
    $encounterTab.Controls.Add($visibleBehaviorLabel)
    $visibleBehaviorCombo = New-ComboBox -Controls $controls -Name "VisibleEncounterBehavior" -X 270 -Y 222 -Width 430
    Add-ComboBoxItem -Combo $visibleBehaviorCombo -Label "Masque fixe" -Value "MasqueFixe"
    Add-ComboBoxItem -Combo $visibleBehaviorCombo -Label "Revelation permanente" -Value "RevelationPermanente"
    Add-ComboBoxItem -Combo $visibleBehaviorCombo -Label "Classique: visible = combat" -Value "RomfsMatch"
    $visibleBehaviorCombo.DisplayMember = "Label"
    $visibleBehaviorCombo.SelectedIndex = 0
    $encounterTab.Controls.Add($visibleBehaviorCombo)

    $encounterDrawModeLabel = New-Label -Text "" -X 18 -Y 266 -Width 220
    $encounterTab.Controls.Add($encounterDrawModeLabel)
    $encounterDrawModeCombo = New-ComboBox -Controls $controls -Name "EncounterDrawMode" -X 270 -Y 262 -Width 430
    Add-ComboBoxItem -Combo $encounterDrawModeCombo -Label "Slot par espèce" -Value "SlotParEspece"
    Add-ComboBoxItem -Combo $encounterDrawModeCombo -Label "Full random" -Value "FullRandom"
    Add-ComboBoxItem -Combo $encounterDrawModeCombo -Label "Visible fixe + tirage random" -Value "VisibleFixeTirageRandom"
    $encounterDrawModeCombo.DisplayMember = "Label"
    $encounterDrawModeCombo.SelectedIndex = 0
    $encounterTab.Controls.Add($encounterDrawModeCombo)

    # Les deux listes ci-dessus decrivaient un seul mecanisme melange, difficile
    # a expliquer. Elles restent creees (presets et rapports y font reference)
    # mais sont masquees : ce sont les deux listes ci-dessous qui pilotent
    # desormais le module. Consequence a garder en tete : dans l'interface le
    # mode de tirage vaut TOUJOURS SlotParEspece, donc c'est bien la liste
    # "stabilite des rencontres" qui decide de la reecriture des tables.
    $visibleBehaviorLabel.Visible = $false
    $visibleBehaviorCombo.Visible = $false
    $encounterDrawModeLabel.Visible = $false
    $encounterDrawModeCombo.Visible = $false

    $liveVisibleModeLabel = New-Label -Text "" -X 18 -Y 226 -Width 250
    $encounterTab.Controls.Add($liveVisibleModeLabel)
    $liveVisibleModeCombo = New-ComboBox -Controls $controls -Name "LiveVisibleMode" -X 270 -Y 222 -Width 330
    Add-ComboBoxItem -Combo $liveVisibleModeCombo -Label "Inchangé (celui du jeu)" -Value "Vanilla"
    Add-ComboBoxItem -Combo $liveVisibleModeCombo -Label "Aléatoire a chaque apparition" -Value "Random"
    Add-ComboBoxItem -Combo $liveVisibleModeCombo -Label "Stable par zone" -Value "Zone"
    Add-ComboBoxItem -Combo $liveVisibleModeCombo -Label "Stable partout" -Value "Global"
    Add-ComboBoxItem -Combo $liveVisibleModeCombo -Label "Découverte de zones" -Value "Decouverte"
    Add-ComboBoxItem -Combo $liveVisibleModeCombo -Label "Découverte, herbe aléatoire" -Value "DecouverteRandom"
    $liveVisibleModeCombo.DisplayMember = "Label"
    $liveVisibleModeCombo.SelectedIndex = 0
    $encounterTab.Controls.Add($liveVisibleModeCombo)
    $encounterTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryLiveVisible" -Text "" -X 620 -Y 224 -Width 300 -Checked $false))

    $liveBattleModeLabel = New-Label -Text "" -X 18 -Y 266 -Width 250
    $encounterTab.Controls.Add($liveBattleModeLabel)
    $liveBattleModeCombo = New-ComboBox -Controls $controls -Name "LiveBattleMode" -X 270 -Y 262 -Width 330
    Add-ComboBoxItem -Combo $liveBattleModeCombo -Label "Inchangé (celui du jeu)" -Value "Vanilla"
    Add-ComboBoxItem -Combo $liveBattleModeCombo -Label "Aléatoire a chaque combat" -Value "Random"
    Add-ComboBoxItem -Combo $liveBattleModeCombo -Label "Stable par zone" -Value "Zone"
    Add-ComboBoxItem -Combo $liveBattleModeCombo -Label "Stable partout" -Value "Global"
    $liveBattleModeCombo.DisplayMember = "Label"
    $liveBattleModeCombo.SelectedIndex = 2
    $encounterTab.Controls.Add($liveBattleModeCombo)
    $encounterTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryLiveBattle" -Text "" -X 620 -Y 264 -Width 300 -Checked $false))

    $liveGenerationLabel = New-Label -Text "" -X 18 -Y 300 -Width 250
    $encounterTab.Controls.Add($liveGenerationLabel)
    $liveGenerationBox = New-TextBox -Controls $controls -Name "LiveGenerationFilter" -X 270 -Y 296 -Width 330 -Text "1,2,3,4,5,6,7,8"
    $encounterTab.Controls.Add($liveGenerationBox)

    $overworldPoolLabel = New-Label -Text "" -X 18 -Y 362 -Width 250
    $encounterTab.Controls.Add($overworldPoolLabel)
    $overworldPoolCombo = New-ComboBox -Controls $controls -Name "OverworldVisiblePoolMode" -X 270 -Y 358 -Width 330
    Add-ComboBoxItem -Combo $overworldPoolCombo -Label "Toutes les espèces" -Value "All"
    Add-ComboBoxItem -Combo $overworldPoolCombo -Label "Visibles en vanilla (les 330 de base)" -Value "Vanilla"
    Add-ComboBoxItem -Combo $overworldPoolCombo -Label "TEST : uniquement les non prévues" -Value "UnusualOnly"
    $overworldPoolCombo.DisplayMember = "Label"
    [void](Set-ComboValue -Combo $overworldPoolCombo -Value (Get-NormalizedOverworldVisiblePoolMode -Value $OverworldVisiblePoolMode))
    $encounterTab.Controls.Add($overworldPoolCombo)
    $overworldHitboxLabel = New-Label -Text "" -X 620 -Y 362 -Width 200
    $encounterTab.Controls.Add($overworldHitboxLabel)
    $overworldHitboxCombo = New-ComboBox -Controls $controls -Name "OverworldVisibleMaxHitbox" -X 830 -Y 358 -Width 250
    Add-ComboBoxItem -Combo $overworldHitboxCombo -Label "Aucune limite" -Value "0"
    Add-ComboBoxItem -Combo $overworldHitboxCombo -Label "Sans les colosses" -Value "250"
    Add-ComboBoxItem -Combo $overworldHitboxCombo -Label "Sans les très gros" -Value "200"
    Add-ComboBoxItem -Combo $overworldHitboxCombo -Label "Sans les gros" -Value "150"
    Add-ComboBoxItem -Combo $overworldHitboxCombo -Label "Compact" -Value "100"
    $overworldHitboxCombo.DisplayMember = "Label"
    if (-not (Set-ComboValue -Combo $overworldHitboxCombo -Value ([string][int]$OverworldVisibleMaxHitbox))) {
        $overworldHitboxCombo.SelectedIndex = 0
    }
    $encounterTab.Controls.Add($overworldHitboxCombo)

    $wildLevelLabel = New-Label -Text "" -X 18 -Y 394 -Width 250
    $encounterTab.Controls.Add($wildLevelLabel)
    $wildLevelBox = New-TextBox -Controls $controls -Name "WildLevelPercent" -X 270 -Y 390 -Width 70 -Text ([string][int]$WildLevelPercent)
    $encounterTab.Controls.Add($wildLevelBox)

    $undergroundModeLabel = New-Label -Text "" -X 18 -Y 326 -Width 180
    $encounterTab.Controls.Add($undergroundModeLabel)
    $undergroundModeCombo = New-ComboBox -Controls $controls -Name "UndergroundMode" -X 270 -Y 322 -Width 330
    Add-ComboBoxItem -Combo $undergroundModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $undergroundModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $undergroundModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $undergroundModeCombo.DisplayMember = "Label"
    $undergroundModeCombo.SelectedIndex = 2
    $encounterTab.Controls.Add($undergroundModeCombo)
    $encounterTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryUnderground" -Text "" -X 620 -Y 324 -Width 300 -Checked $false))

    # Les quatre filtres par categorie tiennent sur UNE ligne, juste sous le
    # filtre general, avec des libelles courts. Presentes en quatre lignes
    # separees, ils ressemblaient a quatre options independantes alors que ce
    # sont des raffinements du meme reglage.
    #
    # Leur Y doit rester DANS la plage de la carte des rencontres, sinon ils
    # flottent par-dessus la section voisine.
    # Le filtre des Pokemon VUS dehors est de retour, sur demande. Il est
    # marque d'un avertissement : personne ne l'a vu fonctionner en jeu, ni sur
    # Epee ni sur Bouclier. Ce qu'on sait : en mode Decouverte il ne peut rien
    # changer, l'herbe restant vanilla jusqu'a la decouverte (randomizer.hpp).
    $filtreVisibleLabel = New-Label -Text "" -X 612 -Y 300 -Width 44
    $encounterTab.Controls.Add($filtreVisibleLabel)
    $encounterTab.Controls.Add((New-TextBox -Controls $controls -Name "GenerationFilterVisible" -X 658 -Y 296 -Width 46 -Text ([string]$GenerationFilterVisible)))
    $filtreBattleLabel = New-Label -Text "" -X 712 -Y 300 -Width 76
    $encounterTab.Controls.Add($filtreBattleLabel)
    $encounterTab.Controls.Add((New-TextBox -Controls $controls -Name "GenerationFilterBattle" -X 790 -Y 296 -Width 46 -Text ([string]$GenerationFilterBattle)))
    $filtreGiftsLabel = New-Label -Text "" -X 844 -Y 300 -Width 64
    $encounterTab.Controls.Add($filtreGiftsLabel)
    $encounterTab.Controls.Add((New-TextBox -Controls $controls -Name "GenerationFilterGifts" -X 910 -Y 296 -Width 46 -Text ([string]$GenerationFilterGifts)))
    $filtreTrainersLabel = New-Label -Text "" -X 964 -Y 300 -Width 72
    $encounterTab.Controls.Add($filtreTrainersLabel)
    $encounterTab.Controls.Add((New-TextBox -Controls $controls -Name "GenerationFilterTrainers" -X 1038 -Y 296 -Width 46 -Text ([string]$GenerationFilterTrainers)))
    # Retire : cette case pretendait garantir que toute espece placee dehors a
    # un modele. La mesure du 2026-09-07 a montre que le compte de 330 especes
    # etait faux (575 archives de modeles, 281 especes modelisees qui ne sont
    # jamais des symboles, 36 symboles vanilla sans archive). Une garantie qui
    # ne tient pas vaut moins que pas de garantie du tout.
    Add-HiddenRemovedBuildOption -Parent $encounterTab -Controls $controls -Name "OverworldModelSafeEncounters"

    # --- Onglet Confort ----------------------------------------------------
    # Deux cartes, parce que ces reglages ne se ressemblent pas du tout :
    #   - la premiere regroupe ce que le MODULE fait pendant la partie. Rien
    #     n'est reecrit dans le ROMFS, mais l'ExeFS doit etre fourni.
    #   - la seconde regroupe ce qui REECRIT personal_total.bin, donc des
    #     modifications permanentes du jeu.
    # Melanger les deux dans une seule liste laissait croire qu'elles ont la
    # meme portee.
    #
    # Les rangees sont espacees de 32 px au lieu de 36 : la carte ajoute un
    # titre et un sous-titre, et l'onglet ne fait que 516 px de haut.
    Initialize-PfControlLibrary
    $qolRuntimeCard = New-Object PokeFeur.Ui.PfCard
    $qolRuntimeCard.Location = New-Object System.Drawing.Point(12, 10)
    $qolRuntimeCard.Size = New-Object System.Drawing.Size(1098, 328)
    $qolTab.Controls.Add($qolRuntimeCard)

    # Conserve pour la traduction : son texte alimente le sous-titre de la carte.
    $qolHeaderLabel = New-Label -Text "" -X 18 -Y 18 -Width 1080
    $qolHeaderLabel.Visible = $false
    $qolTab.Controls.Add($qolHeaderLabel)

    $qolRuntimeCard.Controls.Add((New-CheckBox -Controls $controls -Name "ModOverworldShiny" -Text "" -X 24 -Y 72 -Width 400 -Toggle -Checked ([bool]$ModOverworldShiny)))
    $shinyBoostLabel = New-Label -Text "" -X 436 -Y 76 -Width 250
    $qolRuntimeCard.Controls.Add($shinyBoostLabel)
    $qolRuntimeCard.Controls.Add((New-TextBox -Controls $controls -Name "OverworldShinyBoostPercent" -X 692 -Y 72 -Width 50 -Text ([string][int]$OverworldShinyBoostPercent)))

    $qolRuntimeCard.Controls.Add((New-CheckBox -Controls $controls -Name "ModUncapLevel" -Text "" -X 24 -Y 104 -Width 400 -Toggle -Checked ([bool]$ModUncapLevel)))
    # ModUnderworld : retire de l'interface. Le module le contient bien
    # (cle « underworld » relevee dans le subsdk9 livre, decompresse), mais
    # RandomizeSlotSpawns reecrit overworld_spec->species juste apres lui :
    # son effet est invisible des que « Pokemon que tu VOIS dehors » quitte
    # Inchange. Et il fait piocher les spawners dans une table dont les
    # especes n'ont pas de modele charge dans la zone, ce qui casse la
    # garantie « aucun spawn invisible ». Le controle reste, masque, pour que
    # les presets deja exportes continuent de se relire.
    # Le controle masque va sur l'ONGLET, pas dans la carte : Add-HiddenRemoved-
    # BuildOption le pose en (0,0), ce qui tomberait dans la zone ou PfCard
    # peint son titre. Un test le verifie, et il avait raison.
    Add-HiddenRemovedBuildOption -Parent $qolTab -Controls $controls -Name "ModUnderworld"
    $qolRuntimeCard.Controls.Add((New-CheckBox -Controls $controls -Name "ModExtendedFollowing" -Text "" -X 24 -Y 136 -Width 400 -Toggle -Checked ([bool]$ModExtendedFollowing)))

    $qolRuntimeCard.Controls.Add((New-CheckBox -Controls $controls -Name "ModGlimwoodOverworld" -Text "" -X 24 -Y 168 -Width 400 -Toggle -Checked ([bool]$ModGlimwoodOverworld)))
    $glimwoodSpawnsLabel = New-Label -Text "" -X 436 -Y 172 -Width 250
    $qolRuntimeCard.Controls.Add($glimwoodSpawnsLabel)
    $qolRuntimeCard.Controls.Add((New-TextBox -Controls $controls -Name "GlimwoodMaxSpawns" -X 692 -Y 168 -Width 50 -Text ([string][int]$GlimwoodMaxSpawns)))

    $qolRuntimeCard.Controls.Add((New-CheckBox -Controls $controls -Name "ModFishingTweaks" -Text "" -X 24 -Y 200 -Width 400 -Toggle -Checked ([bool]$ModFishingTweaks)))
    $qolRuntimeCard.Controls.Add((New-CheckBox -Controls $controls -Name "ModSynchroMode" -Text "" -X 24 -Y 232 -Width 400 -Toggle -Checked ([bool]$ModSynchroMode)))
    $qolRuntimeCard.Controls.Add((New-CheckBox -Controls $controls -Name "ModCameraTweaks" -Text "" -X 24 -Y 264 -Width 400 -Toggle -Checked ([bool]$ModCameraTweaks)))
    $qolRuntimeCard.Controls.Add((New-CheckBox -Controls $controls -Name "ModFreecam" -Text "" -X 24 -Y 296 -Width 400 -Toggle -Checked ([bool]$ModFreecam)))
    $qolRuntimeCard.Controls.Add((New-CheckBox -Controls $controls -Name "ModDexAnimations" -Text "" -X 756 -Y 296 -Width 330 -Checked ([bool]$ModDexAnimations)))

    # --- Reglages sur la table Pokemon (ecrits dans le ROMFS) --------------
    $qolPersonalCard = New-Object PokeFeur.Ui.PfCard
    $qolPersonalCard.Location = New-Object System.Drawing.Point(12, 378)
    $qolPersonalCard.Size = New-Object System.Drawing.Size(1098, 136)
    $qolTab.Controls.Add($qolPersonalCard)

    $personalTweakHeaderLabel = New-Label -Text "" -X 18 -Y 382 -Width 1080
    $personalTweakHeaderLabel.Visible = $false
    $qolTab.Controls.Add($personalTweakHeaderLabel)

    $catchRateLabel = New-Label -Text "" -X 24 -Y 72 -Width 220
    $qolPersonalCard.Controls.Add($catchRateLabel)
    $qolPersonalCard.Controls.Add((New-TextBox -Controls $controls -Name "MinimumCatchRate" -X 250 -Y 68 -Width 50 -Text ([string][int]$MinimumCatchRate)))

    $expCurveLabel = New-Label -Text "" -X 326 -Y 72 -Width 110
    $qolPersonalCard.Controls.Add($expCurveLabel)
    $expCurveCombo = New-ComboBox -Controls $controls -Name "ExpCurveMode" -X 442 -Y 68 -Width 170
    Add-ComboBoxItem -Combo $expCurveCombo -Label "Ne pas changer" -Value "Unchanged"
    Add-ComboBoxItem -Combo $expCurveCombo -Label "Tous rapides" -Value "Fast"
    Add-ComboBoxItem -Combo $expCurveCombo -Label "Tous moyens" -Value "MediumFast"
    Add-ComboBoxItem -Combo $expCurveCombo -Label "Tous lents" -Value "Slow"
    $expCurveCombo.DisplayMember = "Label"
    $expCurveCombo.SelectedIndex = 0
    $qolPersonalCard.Controls.Add($expCurveCombo)

    # Quelle attaque chaque CT/DT enseigne. Voisin de « Compatibilite CT / DT »,
    # qui dit qui peut l'apprendre : les deux vont ensemble.
    $tmMoveLabel = New-Label -Text "" -X 620 -Y 72 -Width 150
    $qolPersonalCard.Controls.Add($tmMoveLabel)
    $tmMoveCombo = New-ComboBox -Controls $controls -Name "TmMoveMode" -X 776 -Y 68 -Width 200
    Add-ComboBoxItem -Combo $tmMoveCombo -Label "Ne pas changer" -Value "Unchanged"
    Add-ComboBoxItem -Combo $tmMoveCombo -Label "Permuter entre machines" -Value "Shuffle"
    Add-ComboBoxItem -Combo $tmMoveCombo -Label "Tirage aléatoire" -Value "Random"
    $tmMoveCombo.DisplayMember = "Label"
    $tmMoveCombo.SelectedIndex = 0
    $qolPersonalCard.Controls.Add($tmMoveCombo)

    $tmCompatLabel = New-Label -Text "" -X 24 -Y 104 -Width 196
    $qolPersonalCard.Controls.Add($tmCompatLabel)
    $tmCompatCombo = New-ComboBox -Controls $controls -Name "TmCompatibilityMode" -X 228 -Y 100 -Width 166
    Add-ComboBoxItem -Combo $tmCompatCombo -Label "Ne pas changer" -Value "Unchanged"
    Add-ComboBoxItem -Combo $tmCompatCombo -Label "Une chance sur deux" -Value "Random"
    Add-ComboBoxItem -Combo $tmCompatCombo -Label "Préférer le même type" -Value "SameType"
    Add-ComboBoxItem -Combo $tmCompatCombo -Label "Tout apprendre" -Value "Full"
    $tmCompatCombo.DisplayMember = "Label"
    $tmCompatCombo.SelectedIndex = 0
    $qolPersonalCard.Controls.Add($tmCompatCombo)

    # Le pendant des CT/DT pour les 18 maitres de capacites : meme rangee,
    # parce que c'est la meme question posee sur un autre champ de bits.
    $tutorCompatLabel = New-Label -Text "" -X 410 -Y 104 -Width 180
    $qolPersonalCard.Controls.Add($tutorCompatLabel)
    $tutorCompatCombo = New-ComboBox -Controls $controls -Name "TutorCompatibilityMode" -X 598 -Y 100 -Width 166
    Add-ComboBoxItem -Combo $tutorCompatCombo -Label "Ne pas changer" -Value "Unchanged"
    Add-ComboBoxItem -Combo $tutorCompatCombo -Label "Une chance sur deux" -Value "Random"
    Add-ComboBoxItem -Combo $tutorCompatCombo -Label "Tout apprendre" -Value "Full"
    $tutorCompatCombo.DisplayMember = "Label"
    $tutorCompatCombo.SelectedIndex = 0
    $qolPersonalCard.Controls.Add($tutorCompatCombo)

    $qolPersonalCard.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeWildHeldItems" -Text "" -X 780 -Y 102 -Width 296 -Checked ([bool]$RandomizeWildHeldItems)))

    Initialize-PfControlLibrary
    $statusBox = New-Object PokeFeur.Ui.PfTextBox
    $statusBox.Emphasized = $true
    $statusBox.Multiline = $true
    $statusBox.ReadOnly = $true
    $statusBox.ScrollBars = "Vertical"
    try {
        [System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException)
        [System.Windows.Forms.Application]::add_ThreadException({
            param($sender, $eventArgs)
            if (Test-IsPipelineStoppedException -Exception $eventArgs.Exception) {
                if ($statusBox -and -not $statusBox.IsDisposed) {
                    $statusBox.Text = if ($script:UiLanguage -eq "en") {
                        "Operation cancelled by the UI pipeline."
                    } else {
                        "Opération annulee par le pipeline UI."
                    }
                }
                return
            }

            if ($statusBox -and -not $statusBox.IsDisposed) {
                $statusBox.Text = if ($script:UiLanguage -eq "en") {
                    "Unexpected UI error: $($eventArgs.Exception.Message)"
                } else {
                    "Erreur UI inattendue: $($eventArgs.Exception.Message)"
                }
            }
        })
    } catch {
    }
    Initialize-PfControlLibrary
    $detailsBox = New-Object PokeFeur.Ui.PfTextBox
    # Bordure contrastee : sans elle l'encadre d'aide se confond avec le fond.
    $detailsBox.Emphasized = $true
    $detailsBox.Multiline = $true
    $detailsBox.ReadOnly = $true
    $detailsBox.ScrollBars = "Vertical"
    $detailsBox.Location = New-Object System.Drawing.Point(18, 792)
    # 58 pixels ne laissaient que trois lignes : la moindre explication obligeait
    # a faire defiler. On passe a 110 (environ six lignes) en reprenant 18
    # pixels a la barre d'etat, ce qui ne coute que 34 pixels de hauteur de
    # fenetre - le formulaire n'est pas redimensionnable et doit tenir sur un
    # ecran 1080p.
    # 148 et non 160 : les 12 pixels rendus servent a la barre d'etat en
    # dessous, qui etait trop basse pour afficher une ligne entiere.
    $detailsBox.Size = New-Object System.Drawing.Size(1130, 144)
    $detailsBox.Text = ""
    $form.Controls.Add($detailsBox)

    $uiDescFr = Get-UiStrings -Language "fr"
    $uiDescEn = Get-UiStrings -Language "en"
    Add-ConcreteDescriptionExamples -Ui $uiDescFr -Language "fr"
    Add-ConcreteDescriptionExamples -Ui $uiDescEn -Language "en"
    Register-ControlDescription -Control $trainerSpeciesCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerSpecies; en = $uiDescEn.Descriptions.TrainerSpecies }
    Register-ControlDescription -Control $trainerMoveCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerMoves; en = $uiDescEn.Descriptions.TrainerMoves }
    Register-ControlDescription -Control $trainerSmogonMoveFallbackCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerSmogonMoveFallback; en = $uiDescEn.Descriptions.TrainerSmogonMoveFallback }
    Register-ControlDescription -Control $trainerItemCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerItems; en = $uiDescEn.Descriptions.TrainerItems }
    Register-ControlDescription -Control $trainerItemPoolCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerItemPool; en = $uiDescEn.Descriptions.TrainerItemPool }
    Register-ControlDescription -Control $trainerAddedSlotSpeciesCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerAddedSlotSpecies; en = $uiDescEn.Descriptions.TrainerAddedSlotSpecies }
    Register-ControlDescription -Control $trainerDuplicateModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerDuplicateMode; en = $uiDescEn.Descriptions.TrainerDuplicateMode }
    Register-ControlDescription -Control $bossTeamsScopeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.BossTeamsScope; en = $uiDescEn.Descriptions.BossTeamsScope }
    Register-ControlDescription -Control $trainerAbilityCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerAbility; en = $uiDescEn.Descriptions.TrainerAbility }
    Register-ControlDescription -Control $trainerIvCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerIV; en = $uiDescEn.Descriptions.TrainerIV }
    Register-ControlDescription -Control $trainerEvCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerEV; en = $uiDescEn.Descriptions.TrainerEV }
    Register-ControlDescription -Control $trainerLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerLevel; en = $uiDescEn.Descriptions.TrainerLevel }
    Register-ControlDescription -Control $trainerTeamMinBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerTeamSize; en = $uiDescEn.Descriptions.TrainerTeamSize }
    Register-ControlDescription -Control $trainerTeamMaxBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerTeamSize; en = $uiDescEn.Descriptions.TrainerTeamSize }
    Register-ControlDescription -Control $controls.TrainerTypeThemed -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerTypeThemed; en = $uiDescEn.Descriptions.TrainerTypeThemed }
    Register-ControlDescription -Control $controls.TrainerNatureMode -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.RandomizeNatures; en = $uiDescEn.Descriptions.RandomizeNatures }
    Register-ControlDescription -Control $controls.AllowLegendaryTrainers -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryTrainers; en = $uiDescEn.Descriptions.AllowLegendaryTrainers }
    foreach ($extraName in @("TrainerExtraPokemonBoss", "TrainerExtraPokemonImportant", "TrainerExtraPokemonRegular")) {
        Register-ControlDescription -Control $controls[$extraName] -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerExtraPokemon; en = $uiDescEn.Descriptions.TrainerExtraPokemon }
    }
    Register-ControlDescription -Control $trainerSpecialRuleScopeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerSpecialRuleScope; en = $uiDescEn.Descriptions.TrainerSpecialRuleScope }
    Register-ControlDescription -Control $trainerLegendaryPolicyCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerLegendaryPolicy; en = $uiDescEn.Descriptions.TrainerLegendaryPolicy }
    Register-ControlDescription -Control $diverseTypesCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerForceDiverseTypes; en = $uiDescEn.Descriptions.TrainerForceDiverseTypes }
    Register-ControlDescription -Control $controls.TrainerMinBaseStatTotal -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerMinBaseStatTotal; en = $uiDescEn.Descriptions.TrainerMinBaseStatTotal }
    Register-ControlDescription -Control $shopPriceCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ShopPriceMultiplier; en = $uiDescEn.Descriptions.ShopPriceMultiplier }
    Register-ControlDescription -Control $controls.RandomizeFieldItems -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.RandomizeFieldItems; en = $uiDescEn.Descriptions.RandomizeFieldItems }
    Register-ControlDescription -Control $controls.RandomizeHiddenItems -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.RandomizeHiddenItems; en = $uiDescEn.Descriptions.RandomizeHiddenItems }
    Register-ControlDescription -Control $fieldItemPoolCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.FieldItemPoolMode; en = $uiDescEn.Descriptions.FieldItemPoolMode }
    foreach ($comfortName in @(
        "ModOverworldShiny", "OverworldShinyBoostPercent", "ModUncapLevel",
        "ModExtendedFollowing", "ModGlimwoodOverworld", "GlimwoodMaxSpawns", "ModFishingTweaks",
        "ModSynchroMode", "ModCameraTweaks", "ModFreecam", "ModDexAnimations",
        "MinimumCatchRate", "ExpCurveMode", "TmCompatibilityMode", "TutorCompatibilityMode", "TmMoveMode", "LearnsetMoveMode", "NpcGiftItemMode", "RandomizeWildHeldItems",
        "EvolutionForceGrowth", "EvolutionSameType",
        "FollowEvolutionsForTypes", "FollowEvolutionsForAbilities",
        "EvolutionLimitToThreeStages",
        "StarterMinBaseStatTotal", "StarterMaxBaseStatTotal"
    )) {
        Register-ControlDescription -Control $controls[$comfortName] -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions[$comfortName]; en = $uiDescEn.Descriptions[$comfortName] }
    }
    Register-ControlDescription -Control $trainerShinyBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerShinyChance; en = $uiDescEn.Descriptions.TrainerShinyChance }
    Register-ControlDescription -Control $controls.ForceTrainerFullyEvolved -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceTrainerFullyEvolved; en = $uiDescEn.Descriptions.ForceTrainerFullyEvolved }
    Register-ControlDescription -Control $trainerFullyEvolvedLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceTrainerFullyEvolved; en = $uiDescEn.Descriptions.ForceTrainerFullyEvolved }
    Register-ControlDescription -Control $controls.MaxTrainerAI -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MaxTrainerAI; en = $uiDescEn.Descriptions.MaxTrainerAI }
    Register-ControlDescription -Control $trainerDynamaxLevelCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerDynamaxLevel; en = $uiDescEn.Descriptions.TrainerDynamaxLevel }
    Register-ControlDescription -Control $controls.ForceTrainerCanDynamax -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceTrainerCanDynamax; en = $uiDescEn.Descriptions.ForceTrainerCanDynamax }
    Register-ControlDescription -Control $controls.ForceAllTeamsToSix -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceAllTeams; en = $uiDescEn.Descriptions.ForceAllTeams }
    Register-ControlDescription -Control $controls.ForceBossTeamsToSix -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceBossTeams; en = $uiDescEn.Descriptions.ForceBossTeams }
    Register-ControlDescription -Control $bossTargetsBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceBossTargets; en = $uiDescEn.Descriptions.ForceBossTargets }
    Register-ControlDescription -Control $typeModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TypeMode; en = $uiDescEn.Descriptions.TypeMode }
    Register-ControlDescription -Control $controls.TypesMonotypeOnly -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TypesMonotypeOnly; en = $uiDescEn.Descriptions.TypesMonotypeOnly }
    Register-ControlDescription -Control $abilityModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AbilityMode; en = $uiDescEn.Descriptions.AbilityMode }
    Register-ControlDescription -Control $controls.AllowWonderGuard -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowWonderGuard; en = $uiDescEn.Descriptions.AllowWonderGuard }
    Register-ControlDescription -Control $statModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StatMode; en = $uiDescEn.Descriptions.StatMode }
    Register-ControlDescription -Control $expYieldMultiplierBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ExpYieldMultiplier; en = $uiDescEn.Descriptions.ExpYieldMultiplier }
    Register-ControlDescription -Control $controls.ForceOneExpYield -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceOneExpYield; en = $uiDescEn.Descriptions.ForceOneExpYield }
    Register-ControlDescription -Control $controls.RandomizeMoveTypes -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveTypeMode; en = $uiDescEn.Descriptions.MoveTypeMode }
    Register-ControlDescription -Control $controls.RandomizeMovePower -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePowerMode; en = $uiDescEn.Descriptions.MovePowerMode }
    Register-ControlDescription -Control $movePowerMinBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePowerMode; en = $uiDescEn.Descriptions.MovePowerMode }
    Register-ControlDescription -Control $movePowerMaxBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePowerMode; en = $uiDescEn.Descriptions.MovePowerMode }
    Register-ControlDescription -Control $controls.RandomizeMovePP -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePPMode; en = $uiDescEn.Descriptions.MovePPMode }
    Register-ControlDescription -Control $movePPMinBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePPMode; en = $uiDescEn.Descriptions.MovePPMode }
    Register-ControlDescription -Control $movePPMaxBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePPMode; en = $uiDescEn.Descriptions.MovePPMode }
    Register-ControlDescription -Control $controls.RandomizeMoveAccuracy -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveAccuracyMode; en = $uiDescEn.Descriptions.MoveAccuracyMode }
    Register-ControlDescription -Control $moveAccuracyMinBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveAccuracyMode; en = $uiDescEn.Descriptions.MoveAccuracyMode }
    Register-ControlDescription -Control $moveAccuracyMaxBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveAccuracyMode; en = $uiDescEn.Descriptions.MoveAccuracyMode }
    Register-ControlDescription -Control $controls.RandomizeMoveCategory -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveCategoryMode; en = $uiDescEn.Descriptions.MoveCategoryMode }
    Register-ControlDescription -Control $controls.RandomizePickupItems -DetailsBox $detailsBox -Description @{ fr = "Change les objets qu'on obtient en creusant dans le sol.`r`n  • Tu creuses et tu tombes sur autre chose que prévu.`r`n  • 69 objets concernés.`r`n`r`nC'est séparé des objets posés par terre et des objets cachés."; en = "Changes the items you get by digging in the ground.`r`n  - You dig and you get something else than expected.`r`n  - 69 items are affected.`r`n`r`nThis is separate from ground items and hidden items." }
    Register-ControlDescription -Control $controls.RandomizeShopItems -DetailsBox $detailsBox -Description @{ fr = "Change les objets vendus dans les boutiques.`r`n  • Une Poké Ball en vente peut devenir une Hyper Ball.`r`n  • Une Potion en vente peut devenir un Rappel.`r`n`r`nPar défaut, un objet est remplacé par un objet du même genre : une ball par une ball, un soin par un soin. Sinon la boutique n'affiche rien et le jeu plante à l'achat."; en = "Changes the items sold in shops.`r`n  - A Poke Ball on sale can become an Ultra Ball.`r`n  - A Potion on sale can become a Revive.`r`n`r`nBy default an item is replaced by the same kind of item: a ball by a ball, a healing item by a healing item. Otherwise the shop shows nothing and the game crashes on purchase." }
    Register-ControlDescription -Control $controls.RandomizeTechnicalRecords -DetailsBox $detailsBox -Description @{ fr = "Ajoute les CT et les DT à ce qui peut être tiré au sort.`r`n  • Une CT trouvée par terre peut devenir une autre CT.`r`n  • Une CT en vente peut devenir une autre CT.`r`n`r`nAttention : cette option ne change PAS l'attaque qu'une CT enseigne. Pour ça, c'est l'option « Attaques des CT/DT »."; en = "Adds TMs and TRs to what can be drawn.`r`n  - A TM found on the ground can become another TM.`r`n  - A TM on sale can become another TM.`r`n`r`nNote: this does NOT change which move a TM teaches. That is the TM/TR moves option." }
    Register-ControlDescription -Control $starterModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StarterMode; en = $uiDescEn.Descriptions.StarterMode }
    Register-ControlDescription -Control $starter1Box -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.Starter1; en = $uiDescEn.Descriptions.Starter1 }
    Register-ControlDescription -Control $starter2Box -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.Starter2; en = $uiDescEn.Descriptions.Starter2 }
    Register-ControlDescription -Control $starter3Box -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.Starter3; en = $uiDescEn.Descriptions.Starter3 }
    Register-ControlDescription -Control $controls.PatchStarterRelatedTrainers -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.PatchStarters; en = $uiDescEn.Descriptions.PatchStarters }
    Register-ControlDescription -Control $reportLangCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ReportLanguage; en = $uiDescEn.Descriptions.ReportLanguage }
    Register-ControlDescription -Control $uiLangCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.UiLanguage; en = $uiDescEn.Descriptions.UiLanguage }
    Register-ControlDescription -Control $themeCombo -DetailsBox $detailsBox -Description @{ fr = "Thème de l'interface: clair ou sombre. Le choix est aussi sauvegarde dans les presets JSON."; en = "Interface theme: light or dark. This choice is also saved in JSON presets." }
    Register-ControlDescription -Control $validateBuildButton -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ValidateBuild; en = $uiDescEn.Descriptions.ValidateBuild }
    Register-ControlDescription -Control $buildSummaryButton -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.BuildSummary; en = $uiDescEn.Descriptions.BuildSummary }
    Register-ControlDescription -Control $sourceBox -DetailsBox $detailsBox -Description @{ fr = "Dossier ROMFS original du dump utilisateur. Exemple: selectionne ...\\Epee\\romfs; le logiciel copie seulement les fichiers necessaires puis modifie les tables ROMFS en sortie."; en = "Original ROMFS folder from the user's dump. Example: select ...\\Sword\\romfs; the tool copies only needed files and edits ROMFS tables in the generated output." }
    Register-ControlDescription -Control $sourceExefsBox -DetailsBox $detailsBox -Description @{ fr = "Dossier ExeFS original du dump utilisateur. Exemple: selectionne ...\\Epee\\exefs quand un flux runtime le demande. Le package ExLaunch fourni embarque maintenant son propre main.npdm compatible et son subsdk9 custom."; en = "Original ExeFS folder from the user's dump. Example: select ...\\Sword\\exefs when a runtime flow asks for it. The shipped ExLaunch package now includes its own compatible main.npdm and custom subsdk9." }
    Register-ControlDescription -Control $outputBox -DetailsBox $detailsBox -Description @{ fr = "Dossier de sortie du mod. Exemple: ...\\output\\Epee. Le logiciel cree toujours romfs dedans. Il ajoute aussi exefs\\subsdk9, exefs\\main.npdm et sdmc\\config quand un flux ExLaunch/runtime est actif."; en = "Generated mod folder. Example: ...\\output\\Sword. The tool always creates romfs there. It also adds exefs\\subsdk9, exefs\\main.npdm, and sdmc\\config when an ExLaunch/runtime flow is active." }
    Register-ControlDescription -Control $controls.DisableExpShare -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.DisableExpShare; en = $uiDescEn.Descriptions.DisableExpShare }
    Register-ControlDescription -Control $controls.EarlyBike -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.EarlyBike; en = $uiDescEn.Descriptions.EarlyBike }
    Register-ControlDescription -Control $controls.RuntimePcControls -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.RuntimePcControls; en = $uiDescEn.Descriptions.RuntimePcControls }
    Register-ControlDescription -Control $controls.DynamicExpLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.DynamicExpLevelCap; en = $uiDescEn.Descriptions.DynamicExpLevelCap }
    Register-ControlDescription -Control $controls.StrictBossMaxLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StrictBossMaxLevelCap; en = $uiDescEn.Descriptions.StrictBossMaxLevelCap }
    Register-ControlDescription -Control $controls.MainStorySoftLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MainStorySoftLevelCap; en = $uiDescEn.Descriptions.MainStorySoftLevelCap }
    Register-ControlDescription -Control $controls.GymLeagueStoryLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GymLeagueStoryLevelCap; en = $uiDescEn.Descriptions.GymLeagueStoryLevelCap }
    Register-ControlDescription -Control $controls.StoryMajorBattleOrderLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StoryMajorBattleOrderLevelCap; en = $uiDescEn.Descriptions.StoryMajorBattleOrderLevelCap }
    Register-ControlDescription -Control $controls.AutoInstallToEden -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AutoInstallToEden; en = $uiDescEn.Descriptions.AutoInstallToEden }
    Register-ControlDescription -Control $edenModNameBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.EdenModName; en = $uiDescEn.Descriptions.EdenModName }
    Register-ControlDescription -Control $controls.InstallToRyujinx -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.InstallTargetRyujinx; en = $uiDescEn.Descriptions.InstallTargetRyujinx }
    Register-ControlDescription -Control $controls.ExportEncounterZoneReport -DetailsBox $detailsBox -Description @{ fr = "Exporte encounter-zones.json pour le viewer: zones, methodes d'apparition, chances, niveaux et especes avant/apres. Ce fichier peut spoiler les rencontres."; en = "Exports encounter-zones.json for the viewer: zones, encounter methods, chances, levels, and before/after species. This file can spoil encounters." }
    Register-ControlDescription -Control $evoModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.EvolutionMode; en = $uiDescEn.Descriptions.EvolutionMode }
    Register-ControlDescription -Control $controls.AllowLegendaryEvolutions -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryEvo; en = $uiDescEn.Descriptions.AllowLegendaryEvo }
    Register-ControlDescription -Control $controls.NormalizeFriendshipEvolutions -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeFriendship; en = $uiDescEn.Descriptions.NormalizeFriendship }
    Register-ControlDescription -Control $friendshipLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeFriendship; en = $uiDescEn.Descriptions.NormalizeFriendship }
    Register-ControlDescription -Control $controls.NormalizeTradeEvolutions -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeTrade; en = $uiDescEn.Descriptions.NormalizeTrade }
    Register-ControlDescription -Control $tradeLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeTrade; en = $uiDescEn.Descriptions.NormalizeTrade }
    Register-ControlDescription -Control $controls.NormalizeSpecialEvolutions -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeSpecial; en = $uiDescEn.Descriptions.NormalizeSpecial }
    Register-ControlDescription -Control $specialLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeSpecial; en = $uiDescEn.Descriptions.NormalizeSpecial }
    Register-ControlDescription -Control $giftModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GiftMode; en = $uiDescEn.Descriptions.GiftMode }
    Register-ControlDescription -Control $controls.AllowLegendaryGifts -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryGifts; en = $uiDescEn.Descriptions.AllowLegendaryGifts }
    Register-ControlDescription -Control $tradeModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TradeMode; en = $uiDescEn.Descriptions.TradeMode }
    Register-ControlDescription -Control $controls.AllowLegendaryTrades -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryTrades; en = $uiDescEn.Descriptions.AllowLegendaryTrades }
    Register-ControlDescription -Control $staticEncounterCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StaticMode; en = $uiDescEn.Descriptions.StaticMode }
    Register-ControlDescription -Control $controls.AllowLegendaryStaticEncounters -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryStatic; en = $uiDescEn.Descriptions.AllowLegendaryStatic }
    Register-ControlDescription -Control $staticStableMappingCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StaticStableMapping; en = $uiDescEn.Descriptions.StaticStableMapping }
    Register-ControlDescription -Control $grassEncounterCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GrassMode; en = $uiDescEn.Descriptions.GrassMode }
    Register-ControlDescription -Control $controls.AllowLegendaryGrassEncounters -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryGrass; en = $uiDescEn.Descriptions.AllowLegendaryGrass }
    Register-ControlDescription -Control $grassStableMappingCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GrassStableMapping; en = $uiDescEn.Descriptions.GrassStableMapping }
    Register-ControlDescription -Control $visibleBehaviorCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.VisibleEncounterBehavior; en = $uiDescEn.Descriptions.VisibleEncounterBehavior }
    Register-ControlDescription -Control $encounterDrawModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.EncounterDrawMode; en = $uiDescEn.Descriptions.EncounterDrawMode }
    Register-ControlDescription -Control $liveVisibleModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.LiveVisibleMode; en = $uiDescEn.Descriptions.LiveVisibleMode }
    Register-ControlDescription -Control $liveBattleModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.LiveBattleMode; en = $uiDescEn.Descriptions.LiveBattleMode }
    Register-ControlDescription -Control $controls.AllowLegendaryLiveVisible -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryLiveVisible; en = $uiDescEn.Descriptions.AllowLegendaryLiveVisible }
    Register-ControlDescription -Control $controls.AllowLegendaryLiveBattle -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryLiveBattle; en = $uiDescEn.Descriptions.AllowLegendaryLiveBattle }
    Register-ControlDescription -Control $overworldHitboxCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.OverworldVisibleMaxHitbox; en = $uiDescEn.Descriptions.OverworldVisibleMaxHitbox }
    Register-ControlDescription -Control $overworldPoolCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.OverworldVisiblePoolMode; en = $uiDescEn.Descriptions.OverworldVisiblePoolMode }
    Register-ControlDescription -Control $liveGenerationBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.LiveGenerationFilter; en = $uiDescEn.Descriptions.LiveGenerationFilter }
    Register-ControlDescription -Control $wildLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.WildLevelPercent; en = $uiDescEn.Descriptions.WildLevelPercent }
    Register-ControlDescription -Control $undergroundModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.UndergroundMode; en = $uiDescEn.Descriptions.UndergroundMode }
    Register-ControlDescription -Control $controls.AllowLegendaryUnderground -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryUnderground; en = $uiDescEn.Descriptions.AllowLegendaryUnderground }
    Register-ControlDescription -Control $controls.GenerationFilterVisible -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GenerationFilterVisible; en = $uiDescEn.Descriptions.GenerationFilterVisible }
    Register-ControlDescription -Control $controls.GenerationFilterBattle -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GenerationFilterBattle; en = $uiDescEn.Descriptions.GenerationFilterBattle }
    Register-ControlDescription -Control $controls.GenerationFilterGifts -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GenerationFilterGifts; en = $uiDescEn.Descriptions.GenerationFilterGifts }
    Register-ControlDescription -Control $controls.GenerationFilterTrainers -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GenerationFilterTrainers; en = $uiDescEn.Descriptions.GenerationFilterTrainers }
    Register-ControlDescription -Control $controls.EvolutionMinBstGain -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.EvolutionMinBstGain; en = $uiDescEn.Descriptions.EvolutionMinBstGain }
    Register-ControlDescription -Control $controls.WriteInstallationPackage -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.WriteInstallationPackage; en = $uiDescEn.Descriptions.WriteInstallationPackage }
    Register-ControlDescription -Control $controls.StrictDataFiles -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StrictDataFiles; en = $uiDescEn.Descriptions.StrictDataFiles }
    Register-ControlDescription -Control $controls.RandomizeTrainerNatures -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.RandomizeTrainerNatures; en = $uiDescEn.Descriptions.RandomizeTrainerNatures }
    Register-ControlDescription -Control $controls.TrainerBagItemMode -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerBagItemMode; en = $uiDescEn.Descriptions.TrainerBagItemMode }
    Register-ControlDescription -Control $controls.ShopItemMode -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ShopItemMode; en = $uiDescEn.Descriptions.ShopItemMode }

    # 24 px de haut moins 2 x 8 px de rembourrage ne laissaient que 8 px pour
    # une police qui en occupe 17 : le texte etait coupe en deux dans la
    # hauteur. 36 px laissent une ligne complete, le reste defile.
    $statusBox.Location = New-Object System.Drawing.Point(18, 940)
    $statusBox.Size = New-Object System.Drawing.Size(1130, 36)
    $statusBox.Text = ""
    $form.Controls.Add($statusBox)

    $script:ApplyingUiLanguage = $false
    $script:ApplyingCompatibilityUi = $false
    $script:LastDetailsDescription = $null
    function Apply-UiLanguage {
        param([string]$Language)

        if ($script:ApplyingUiLanguage) {
            return
        }
        $script:ApplyingUiLanguage = $true

        $script:UiLanguage = if ($Language -eq "en") { "en" } else { "fr" }
        $ui = Get-UiStrings -Language $script:UiLanguage

        $form.Text = $ui.FormTitle
        $sourceLabel.Text = $ui.SourceLabel
        $sourceExefsLabel.Text = $ui.SourceExefsLabel
        $outputLabel.Text = $ui.OutputLabel
        $gameVersionLabel.Text = $ui.GameVersion
        $seedLabel.Text = $ui.Seed
        $uiLangLabel.Text = $ui.UiLanguage
        $reportLangLabel.Text = $ui.ReportLanguage
        $themeLabel.Text = $ui.Theme
        # Sous-titre et noms des versions du jeu : ecrits en dur en francais a la
        # construction, ils ne suivaient pas le selecteur de langue.
        $heroSub.Text = if ($script:UiLanguage -eq "en") {
            "Randomizer Sword / Shield - ROMFS, ExLaunch, presets and emulator install"
        } else {
            "Randomizer Sword / Shield - ROMFS, ExLaunch, presets et installation émulateur"
        }
        if ($gameVersionCombo.Items.Count -ge 2) {
            # On modifie les libelles EN PLACE : vider la liste declencherait les
            # evenements de selection et perdrait la version choisie.
            $gameVersionCombo.Items[0].Label = if ($script:UiLanguage -eq "en") { "Shield" } else { "Bouclier" }
            $gameVersionCombo.Items[1].Label = if ($script:UiLanguage -eq "en") { "Sword" } else { "Épée" }
            $gameVersionCombo.Invalidate()
        }
        $browseSource.Text = $ui.Browse
        $browseSourceExefs.Text = $ui.Browse
        $browseOutput.Text = $ui.Browse
        $runButton.Text = $ui.Generate
        $validateBuildButton.Text = $ui.ValidateBuild
        $buildSummaryButton.Text = $ui.BuildSummary
        $exportPresetButton.Text = if ($script:UiLanguage -eq "en") { "Export preset" } else { "Exporter preset" }
        $importPresetButton.Text = if ($script:UiLanguage -eq "en") { "Import preset" } else { "Importer preset" }
        $generalTab.Text = $ui.Tabs.General
        $trainerTab.Text = $ui.Tabs.Trainers
        $pokemonTab.Text = $ui.Tabs.Pokemon
        $evoTab.Text = $ui.Tabs.Evolutions
        $giftTab.Text = $ui.Tabs.Gifts
        $qolTab.Text = $ui.Tabs.Comfort
        $isEn = ($script:UiLanguage -eq "en")
        $controls.EvolutionForceGrowth.Text = if ($isEn) { "Evolutions must be stronger than what they come from" } else { "Les évolutions doivent être plus fortes que leur forme de base" }
        $controls.EvolutionSameType.Text = if ($isEn) { "Evolutions must share a type with what they come from" } else { "Les évolutions doivent partager un type avec leur forme de base" }
        $controls.EvolutionLimitToThreeStages.Text = if ($isEn) { "No evolution chain longer than three stages" } else { "Aucune chaîne d'évolution de plus de trois stades" }
        $starterBstLabel.Text = if ($isEn) { "Starter total stats, min / max" } else { "Stats totales des starters, mini / maxi" }
        $qolHeaderLabel.Text = if ($isEn) {
            "These options are applied by the module while you play. They need the ExeFS to be provided, and they rewrite no game file."
        } else {
            "Ces options sont appliquées par le module pendant que tu joues. Elles demandent que l'ExeFS soit fourni, et ne réécrivent aucun fichier du jeu."
        }
        if ($qolRuntimeCard) {
            $qolRuntimeCard.Title = if ($isEn) { "Applied by the module while you play" } else { "Appliqué par le module pendant la partie" }
            $qolRuntimeCard.Subtitle = $qolHeaderLabel.Text
            $qolRuntimeCard.Invalidate()
        }
        $controls.ModOverworldShiny.Text = if ($isEn) { "See shiny Pokemon in the overworld" } else { "Voir les chromatiques dehors" }
        $shinyBoostLabel.Text = if ($isEn) { "Forced shiny chance (%):" } else { "Chance de chromatique forcée (%) :" }
        $controls.ModUncapLevel.Text = if ($isEn) { "Remove the Wild Area level lock" } else { "Retirer le verrou de niveau de la Zone Sauvage" }
        $controls.ModExtendedFollowing.Text = if ($isEn) { "Following Pokemon allowed in the Wild Area" } else { "Pokémon qui suit autorisé dans la Zone Sauvage" }
        $controls.ModGlimwoodOverworld.Text = if ($isEn) { "Visible Pokemon in Glimwood Tangle" } else { "Pokémon visibles au Bois Chancelier" }
        $glimwoodSpawnsLabel.Text = if ($isEn) { "Maximum number of spawns:" } else { "Nombre maximum d'apparitions :" }
        $filtreVisibleLabel.Text = if ($isEn) { "seen*" } else { "vues*" }
        $filtreBattleLabel.Text = if ($isEn) { "fought" } else { "affrontées" }
        $filtreGiftsLabel.Text = if ($isEn) { "given" } else { "données" }
        $filtreTrainersLabel.Text = if ($isEn) { "trainers" } else { "adverses" }
        $evoMinBstLabel.Text = if ($isEn) { "Minimum stat gain on evolution:" } else { "Gain minimal de stats à l'évolution :" }
        $trainerBagLabel.Text = if ($isEn) { "Trainer bag:" } else { "Sac des dresseurs :" }
        $controls.WriteInstallationPackage.Text = if ($isEn) { "Create the Installation folder" } else { "Créer le dossier Installation" }
        $controls.StrictDataFiles.Text = if ($isEn) { "Stop if a data file is missing" } else { "Arrêter si un fichier de données manque" }
        $shopItemModeLabel.Text = if ($isEn) { "Shop items:" } else { "Objets des boutiques :" }
        $controls.ModFishingTweaks.Text = if ($isEn) { "Keep the fishing chain after a brilliant Pokemon" } else { "Garder la série de pêche après un Pokémon brillant" }
        $controls.ModSynchroMode.Text = if ($isEn) { "Pilot your following Pokemon (L + R)" } else { "Piloter le Pokémon qui te suit (L + R)" }
        $controls.ModCameraTweaks.Text = if ($isEn) { "Freer camera (speed, angle, distance)" } else { "Caméra plus libre (vitesse, angle, distance)" }
        $controls.ModFreecam.Text = if ($isEn) { "Free camera detached from the player" } else { "Caméra libre détachée du joueur" }
        $controls.ModDexAnimations.Text = if ($isEn) { "Battle animation picker (Ditto)" } else { "Choix d'animation de combat (Métamorph)" }
        $personalTweakHeaderLabel.Text = if ($isEn) {
            "Pokemon data settings below. Unlike the boxes above, these DO rewrite a game file."
        } else {
            "Réglages sur les données Pokémon ci-dessous. Contrairement aux cases du dessus, ceux-là réécrivent bien un fichier du jeu."
        }
        if ($qolPersonalCard) {
            $qolPersonalCard.Title = if ($isEn) { "Rewrites a game file" } else { "Réécrit un fichier du jeu" }
            $qolPersonalCard.Subtitle = $personalTweakHeaderLabel.Text
            $qolPersonalCard.Invalidate()
        }
        $catchRateLabel.Text = if ($isEn) { "Minimum catch rate:" } else { "Taux de capture mini :" }
        $expCurveLabel.Text = if ($isEn) { "EXP curve:" } else { "Courbe d'EXP :" }
        $tmCompatLabel.Text = if ($isEn) { "TM / TR compatibility:" } else { "Compatibilité CT / DT :" }
        $tmMoveLabel.Text = if ($isEn) { "TM / TR moves:" } else { "Attaques des CT / DT :" }
        $tutorCompatLabel.Text = if ($isEn) { "Tutor compatibility:" } else { "Maîtres de capacités :" }
        $learnsetMoveLabel.Text = if ($isEn) { "Level-up moves:" } else { "Attaques apprises :" }
        $controls.RandomizeWildHeldItems.Text = if ($isEn) { "Randomize wild Pokemon held items" } else { "Randomiser les objets tenus des sauvages" }
        $encounterTab.Text = $ui.Tabs.Encounters
        $helpTab.Text = $ui.Tabs.Help
        $resetTab.Text = $ui.Tabs.Reset

        for ($i = 0; $i -lt $generalInfoLabels.Count; $i++) {
            $generalInfoLabels[$i].Text = $ui.GeneralLines[$i]
        }
        $controls.DisableExpShare.Text = $ui.Labels.DisableExpShare
        $controls.EarlyBike.Text = $ui.Labels.EarlyBike
        $controls.RuntimePcControls.Text = $ui.Labels.RuntimePcControls
        $controls.DynamicExpLevelCap.Text = $ui.Labels.DynamicExpLevelCap
        $controls.StrictBossMaxLevelCap.Text = $ui.Labels.StrictBossMaxLevelCap
        $controls.MainStorySoftLevelCap.Text = $ui.Labels.MainStorySoftLevelCap
        $controls.GymLeagueStoryLevelCap.Text = $ui.Labels.GymLeagueStoryLevelCap
        $controls.StoryMajorBattleOrderLevelCap.Text = $ui.Labels.StoryMajorBattleOrderLevelCap
        $controls.AutoInstallToEden.Text = $ui.Labels.AutoInstallToEden
        $edenModNameLabel.Text = $ui.Labels.EdenModName
        $controls.InstallToRyujinx.Text = $ui.Labels.InstallTargetRyujinx
        $controls.ExportEncounterZoneReport.Text = if ($script:UiLanguage -eq "en") { "Encounter zones JSON" } else { "JSON zones rencontres" }
        $resetInfoLabel.Text = $ui.Labels.ResetDefault
        $resetButton.Text = $ui.Labels.ResetButton

        $trainerSpeciesLabel.Text = $ui.Labels.TrainerSpecies
        $trainerMovesLabel.Text = $ui.Labels.TrainerMoves
        $trainerItemsLabel.Text = $ui.Labels.TrainerItems
        $trainerItemPoolLabel.Text = $ui.Labels.TrainerItemPool
        $trainerAbilityLabel.Text = $ui.Labels.TrainerAbility
        $trainerIvLabel.Text = $ui.Labels.TrainerIV
        $trainerEvLabel.Text = $ui.Labels.TrainerEV
        $trainerAddedSlotSpeciesLabel.Text = $ui.Labels.TrainerAddedSlotSpecies
        $trainerDuplicateModeLabel.Text = $ui.Labels.TrainerDuplicateMode
        $bossTeamsScopeLabel.Text = $ui.Labels.BossTeamsScope
        $trainerLevelLabel.Text = $ui.Labels.TrainerLevel
        $trainerTeamMinLabel.Text = $ui.Labels.TrainerTeamMin
        $trainerTeamMaxLabel.Text = $ui.Labels.TrainerTeamMax
        $trainerNatureModeLabel.Text = $ui.Labels.RandomizeNatures
        $controls.TrainerTypeThemed.Text = $ui.Labels.TrainerTypeThemed
        $trainerShinyLabel.Text = $ui.Labels.TrainerShinyChance
        $controls.ForceTrainerFullyEvolved.Text = $ui.Labels.ForceTrainerFullyEvolved
        $trainerFullyEvolvedLevelLabel.Text = $ui.Labels.TrainerFullyEvolvedLevel
        $controls.MaxTrainerAI.Text = $ui.Labels.MaxTrainerAI
        $trainerDynamaxLevelLabel.Text = $ui.Labels.TrainerDynamaxLevel
        $controls.ForceTrainerCanDynamax.Text = $ui.Labels.ForceTrainerCanDynamax
        $controls.ForceAllTeamsToSix.Text = $ui.Labels.ForceAllTeams
        $controls.ForceBossTeamsToSix.Text = $ui.Labels.ForceBossTeams
        $controls.AllowLegendaryTrainers.Text = $ui.Labels.AllowLegendaryTrainers
        $trainerExtraPokemonLabel.Text = $ui.Labels.TrainerExtraPokemon
        $trainerExtraBossLabel.Text = $ui.Labels.TrainerExtraBoss
        $trainerExtraImportantLabel.Text = $ui.Labels.TrainerExtraImportant
        $trainerExtraRegularLabel.Text = $ui.Labels.TrainerExtraRegular
        $trainerSpecialRuleLabel.Text = $ui.Labels.TrainerSpecialRule
        $trainerMinBstLabel.Text = $ui.Labels.TrainerMinBaseStatTotal
        $diverseTypesLabel.Text = if ($script:UiLanguage -eq "en") { "Diverse types:" } else { "Types variés :" }
        $bossScopeValue = if ($controls.BossTeamsToSixScope) { Get-ComboValue -Combo $controls.BossTeamsToSixScope } else { $script:BossTeamsToSixScope }
        $bossTargetsBox.Text = Get-BossTrainerUniqueNamesText -Language $script:UiLanguage -Scope $bossScopeValue
        $typeModeLabel.Text = $ui.Labels.TypeMode
        $controls.TypesMonotypeOnly.Text = $ui.Labels.ForceMonotype
        $abilityModeLabel.Text = $ui.Labels.AbilityMode
        $controls.AllowWonderGuard.Text = $ui.Labels.AllowWonderGuard
        $statModeLabel.Text = $ui.Labels.StatMode
        $expYieldMultiplierLabel.Text = $ui.Labels.ExpYieldMultiplier
        $controls.ForceOneExpYield.Text = $ui.Labels.ForceOneExpYield
        $controls.RandomizeMoveTypes.Text = $ui.Labels.MoveTypeMode
        $controls.RandomizeMovePower.Text = $ui.Labels.MovePowerMode
        $movePowerMinLabel.Text = $ui.Labels.MovePowerMin
        $movePowerMaxLabel.Text = $ui.Labels.MovePowerMax
        $controls.RandomizeMovePP.Text = $ui.Labels.MovePPMode
        $movePPMinLabel.Text = $ui.Labels.MovePPMin
        $movePPMaxLabel.Text = $ui.Labels.MovePPMax
        $controls.RandomizeMoveAccuracy.Text = $ui.Labels.MoveAccuracyMode
        $moveAccuracyMinLabel.Text = $ui.Labels.MoveAccuracyMin
        $moveAccuracyMaxLabel.Text = $ui.Labels.MoveAccuracyMax
        $controls.RandomizeMoveCategory.Text = $ui.Labels.MoveCategoryMode
        $controls.RandomizePickupItems.Text = if ($script:UiLanguage -eq "en") { "Pickup / field items" } else { "Objets ramassables" }
        $controls.RandomizeShopItems.Text = if ($script:UiLanguage -eq "en") { "Shop items" } else { "Objets boutiques" }
        $shopPriceLabel.Text = if ($script:UiLanguage -eq "en") { "Shop prices" } else { "Prix des boutiques" }
        $controls.FollowEvolutionsForTypes.Text = if ($script:UiLanguage -eq "en") { "Evolutions keep their family's types" } else { "Les évolutions gardent les types de leur famille" }
        $controls.FollowEvolutionsForAbilities.Text = if ($script:UiLanguage -eq "en") { "Evolutions keep their family's abilities" } else { "Les évolutions gardent les talents de leur famille" }
        $controls.RandomizeFieldItems.Text = if ($script:UiLanguage -eq "en") { "Items lying on the ground" } else { "Objets posés au sol" }
        $controls.RandomizeHiddenItems.Text = if ($script:UiLanguage -eq "en") { "Hidden items" } else { "Objets cachés" }
        $controls.RandomizeTechnicalRecords.Text = if ($script:UiLanguage -eq "en") { "TM/TR item IDs" } else { "Objets CT/TR" }
        $evoModeLabel.Text = $ui.Labels.EvolutionMode
        $controls.AllowLegendaryEvolutions.Text = $ui.Labels.AllowLegendaryEvo
        $controls.NormalizeFriendshipEvolutions.Text = $ui.Labels.NormalizeFriendship
        $friendshipLevelLabel.Text = $ui.Labels.FriendshipLevel
        $controls.NormalizeTradeEvolutions.Text = $ui.Labels.NormalizeTrade
        $tradeLevelLabelEvo.Text = $ui.Labels.TradeLevel
        $controls.NormalizeSpecialEvolutions.Text = $ui.Labels.NormalizeSpecial
        $specialLevelLabelEvo.Text = $ui.Labels.SpecialLevel
        $giftModeLabel.Text = $ui.Labels.GiftMode
        $npcGiftItemLabel.Text = if ($isEn) { "Items given by NPCs:" } else { "Objets offerts par les PNJ :" }
        $starterModeLabel.Text = $ui.Labels.StarterMode
        $controls.AllowLegendaryGifts.Text = $ui.Labels.AllowLegendaryGifts
        $manualStarterGroupLabel.Text = $ui.Labels.ManualStarterGroup
        $starter1Label.Text = $ui.Labels.Slot1
        $starter2Label.Text = $ui.Labels.Slot2
        $starter3Label.Text = $ui.Labels.Slot3
        $controls.PatchStarterRelatedTrainers.Text = $ui.Labels.PatchStarters
        $tradeModeLabel.Text = $ui.Labels.TradeMode
        $controls.AllowLegendaryTrades.Text = $ui.Labels.AllowLegendaryTrades
        $staticModeLabel.Text = $ui.Labels.StaticMode
        $controls.AllowLegendaryStaticEncounters.Text = $ui.Labels.AllowLegendaryStatic
        $staticStableMappingLabel.Text = $ui.Labels.StaticStableMapping
        $grassModeLabel.Text = $ui.Labels.GrassMode
        $controls.AllowLegendaryGrassEncounters.Text = $ui.Labels.AllowLegendaryGrass
        $grassStableMappingLabel.Text = $ui.Labels.GrassStableMapping
        $visibleBehaviorLabel.Text = $ui.Labels.VisibleEncounterBehavior
        $encounterDrawModeLabel.Text = $ui.Labels.EncounterDrawMode
        $liveVisibleModeLabel.Text = $ui.Labels.LiveVisibleMode
        $liveBattleModeLabel.Text = $ui.Labels.LiveBattleMode
        $liveGenerationLabel.Text = $ui.Labels.LiveGenerationFilter
        $wildLevelLabel.Text = if ($script:UiLanguage -eq "en") { "Wild level change (%)" } else { "Niveau des sauvages (%)" }
        $controls.AllowLegendaryLiveVisible.Text = $ui.Labels.AllowLegendaryLiveVisible
        $controls.AllowLegendaryLiveBattle.Text = $ui.Labels.AllowLegendaryLiveBattle
        $undergroundModeLabel.Text = $ui.Labels.UndergroundMode
        $controls.AllowLegendaryUnderground.Text = $ui.Labels.AllowLegendaryUnderground

        Set-LocalizedComboItems -Combo $uiLangCombo -Items @(
            @{ Label = $ui.UiLanguageFrench; Value = "fr" },
            @{ Label = $ui.UiLanguageEnglish; Value = "en" }
        )
        Set-LocalizedComboItems -Combo $reportLangCombo -Items @(
            @{ Label = $ui.ReportLanguageFrench; Value = "fr" },
            @{ Label = $ui.ReportLanguageEnglish; Value = "en" }
        )
        Set-LocalizedComboItems -Combo $themeCombo -Items @(
            @{ Label = $ui.ThemeLight; Value = "Light" },
            @{ Label = $ui.ThemeDark; Value = "Dark" }
        )
        Set-LocalizedComboItems -Combo $trainerSpeciesCombo -Items @(
            @{ Label = $ui.ModeRandom; Value = "Random" },
            @{ Label = $ui.ModeSimilarBST; Value = "SimilarBST" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerMoveCombo -Items @(
            @{ Label = $ui.TrainerMoveRandom4; Value = "Random4" },
            @{ Label = $ui.TrainerMoveLevel4; Value = "LastLevelUp4" },
            @{ Label = $ui.TrainerMoveSmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerMoveSmogonLegacy; Value = "SmogonLegacy" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        $trainerSmogonMoveFallbackLabel.Text = $ui.Labels.TrainerSmogonMoveFallback
        Set-LocalizedComboItems -Combo $trainerSmogonMoveFallbackCombo -Items @(
            @{ Label = $ui.TrainerSmogonMoveFallbackLevel; Value = "LastLevelUp4" },
            @{ Label = $ui.TrainerSmogonMoveFallbackRandom; Value = "Random4" },
            @{ Label = $ui.TrainerSmogonMoveFallbackUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerItemCombo -Items @(
            @{ Label = $ui.TrainerItemRandomPresent; Value = "RandomWhenPresent" },
            @{ Label = $ui.TrainerItemForceAll; Value = "ForceAll" },
            @{ Label = $ui.TrainerItemSmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerItemSmogonLegacy; Value = "SmogonLegacy" },
            @{ Label = $ui.TrainerItemRemoveAll; Value = "RemoveAll" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerItemPoolCombo -Items @(
            @{ Label = $ui.TrainerItemPoolBattle; Value = "Battle" },
            @{ Label = $ui.TrainerItemPoolFull; Value = "FullRandom" }
        )
        Set-LocalizedComboItems -Combo $trainerAbilityCombo -Items @(
            @{ Label = $ui.TrainerAbilityRandom; Value = "RandomSlot" },
            @{ Label = $ui.TrainerAbilitySmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerAbilitySmogonLegacy; Value = "SmogonLegacy" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerIvCombo -Items @(
            @{ Label = $ui.TrainerIVMax; Value = "Max31" },
            @{ Label = $ui.TrainerIVRandom; Value = "Random" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerEvCombo -Items @(
            @{ Label = $ui.TrainerEVSmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerEVSmogonLegacy; Value = "SmogonLegacy" },
            @{ Label = $ui.TrainerEVRandom; Value = "RandomLegal" },
            @{ Label = $ui.TrainerEVZero; Value = "Zero" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerNatureModeCombo -Items @(
            @{ Label = $ui.TrainerNatureUnchanged; Value = "Unchanged" },
            @{ Label = $ui.TrainerNatureRandom; Value = "Random" },
            @{ Label = $ui.TrainerNatureSmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerNatureSmogonLegacy; Value = "SmogonLegacy" }
        )
        Set-LocalizedComboItems -Combo $trainerAddedSlotSpeciesCombo -Items @(
            @{ Label = $ui.TrainerAddedSlotRandom; Value = "Random" },
            @{ Label = $ui.TrainerAddedSlotSimilarBST; Value = "SimilarBST" },
            @{ Label = $ui.TrainerAddedSlotSameType; Value = "SameTypeRandom" },
            @{ Label = $ui.TrainerAddedSlotSameTypeBST; Value = "SameTypeBST" }
        )
        Set-LocalizedComboItems -Combo $trainerDuplicateModeCombo -Items @(
            @{ Label = $ui.TrainerDuplicateNoDuplicates; Value = "NoDuplicates" },
            @{ Label = $ui.TrainerDuplicateNormal; Value = "Normal" }
        )
        Set-LocalizedComboItems -Combo $bossTeamsScopeCombo -Items @(
            @{ Label = $ui.BossScopeMajor; Value = "MajorBosses" },
            @{ Label = $ui.BossScopeGymLeague; Value = "GymLeague" }
        )
        Set-LocalizedComboItems -Combo $trainerDynamaxLevelCombo -Items @(
            @{ Label = $ui.Labels.TrainerDynamaxUnchanged; Value = "Unchanged" },
            @{ Label = $ui.Labels.TrainerDynamaxMax; Value = "Max10" },
            @{ Label = $ui.Labels.TrainerDynamaxRandom; Value = "Random0To10" }
        )
        Set-LocalizedComboItems -Combo $typeModeCombo -Items @(
            @{ Label = if ($script:UiLanguage -eq "en") { "Randomize Pokemon types" } else { "Randomiser les types" }; Value = "Random" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $abilityModeCombo -Items @(
            @{ Label = if ($script:UiLanguage -eq "en") { "Randomize species abilities" } else { "Randomiser les talents des espèces" }; Value = "Random" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $statModeCombo -Items @(
            @{ Label = $ui.StatShuffle; Value = "Shuffle" },
            @{ Label = $ui.StatRedistribute; Value = "Redistribute" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        foreach ($combo in @($evoModeCombo, $giftModeCombo, $tradeModeCombo, $staticEncounterCombo, $grassEncounterCombo, $undergroundModeCombo)) {
            Set-LocalizedComboItems -Combo $combo -Items @(
                @{ Label = $ui.ModeRandom; Value = "Random" },
                @{ Label = $ui.ModeSimilarBST; Value = "SimilarBST" },
                @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
            )
        }
        Set-LocalizedComboItems -Combo $starterModeCombo -Items @(
            @{ Label = $ui.StarterRandom; Value = "Random" },
            @{ Label = $ui.StarterSimilarBST; Value = "SimilarBST" },
            @{ Label = $ui.StarterUnchanged; Value = "Unchanged" }
        )
        foreach ($combo in @($staticStableMappingCombo, $grassStableMappingCombo)) {
            Set-LocalizedComboItems -Combo $combo -Items @(
                @{ Label = $ui.MappingSlot; Value = "Slot" },
                @{ Label = $ui.MappingSpecies; Value = "Species" }
            )
        }
        Set-LocalizedComboItems -Combo $visibleBehaviorCombo -Items @(
            @{ Label = if ($script:UiLanguage -eq "en") { "Fixed mask" } else { "Masque fixe" }; Value = "MasqueFixe" },
            @{ Label = if ($script:UiLanguage -eq "en") { "Permanent reveal" } else { "Revelation permanente" }; Value = "RevelationPermanente" },
            @{ Label = if ($script:UiLanguage -eq "en") { "Classic: visible = battle" } else { "Classique: visible = combat" }; Value = "RomfsMatch" }
        )
        Set-LocalizedComboItems -Combo $encounterDrawModeCombo -Items @(
            @{ Label = if ($script:UiLanguage -eq "en") { "Slot by species" } else { "Slot par espèce" }; Value = "SlotParEspece" },
            @{ Label = if ($script:UiLanguage -eq "en") { "Full random" } else { "Full random" }; Value = "FullRandom" },
            @{ Label = if ($script:UiLanguage -eq "en") { "Fixed visible + random battle" } else { "Visible fixe + tirage random" }; Value = "VisibleFixeTirageRandom" }
        )

        # Ces vingt-et-une listes gardaient les libelles francais ecrits en dur a
        # leur creation : en anglais, l'interface affichait encore "Inchange
        # (celui du jeu)" ou "Stable par zone". Les VALEURS internes ne bougent
        # pas, donc les presets deja exportes restent valides.
        Set-LocalizedComboItems -Combo $trainerBagCombo -Items @(
            @{ Label = $ui.ModeVanillaGame; Value = "Unchanged" },
            @{ Label = $ui.BagEmpty; Value = "None" },
            @{ Label = $ui.BagRandom; Value = "Random" }
        )
        Set-LocalizedComboItems -Combo $diverseTypesCombo -Items @(
            @{ Label = $ui.ScopeOff; Value = "Off" },
            @{ Label = $ui.ScopeGymLeague; Value = "GymLeague" },
            @{ Label = $ui.ScopeAllBosses; Value = "AllBosses" },
            @{ Label = $ui.ScopeEveryone; Value = "Everyone" }
        )
        Set-LocalizedComboItems -Combo $trainerSpecialRuleScopeCombo -Items @(
            @{ Label = $ui.ScopeGymLeague; Value = "GymLeague" },
            @{ Label = $ui.ScopeAllBosses; Value = "AllBosses" },
            @{ Label = $ui.ScopeEveryone; Value = "Everyone" }
        )
        Set-LocalizedComboItems -Combo $trainerLegendaryPolicyCombo -Items @(
            @{ Label = $ui.LegendaryPolicyUnchanged; Value = "Unchanged" },
            @{ Label = $ui.LegendaryPolicyNone; Value = "None" },
            @{ Label = $ui.LegendaryPolicyOneEach; Value = "OneEach" },
            @{ Label = $ui.LegendaryPolicyAll; Value = "All" }
        )
        Set-LocalizedComboItems -Combo $learnsetMoveCombo -Items @(
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" },
            @{ Label = $ui.LearnsetShuffle; Value = "Shuffle" },
            @{ Label = $ui.DrawRandom; Value = "Random" },
            @{ Label = $ui.LearnsetFullRandom; Value = "FullRandom" }
        )
        Set-LocalizedComboItems -Combo $shopItemModeCombo -Items @(
            @{ Label = $ui.ShopItemSamePocket; Value = "SamePocket" },
            @{ Label = $ui.ShopItemFullRandom; Value = "FullRandom" }
        )
        Set-LocalizedComboItems -Combo $shopPriceCombo -Items @(
            @{ Label = $ui.ShopPriceFree; Value = "0" },
            @{ Label = $ui.ShopPriceHalf; Value = "0.5" },
            @{ Label = $ui.ShopPriceNormal; Value = "1" },
            @{ Label = $ui.ShopPriceDouble; Value = "2" },
            @{ Label = $ui.ShopPriceExpensive; Value = "5" },
            @{ Label = $ui.ShopPriceRandomSmall; Value = "random:100:5000" },
            @{ Label = $ui.ShopPriceRandomMedium; Value = "random:300:20000" },
            @{ Label = $ui.ShopPriceRandomWide; Value = "random:1:999999" }
        )
        Set-LocalizedComboItems -Combo $fieldItemPoolCombo -Items @(
            @{ Label = $ui.FieldPoolSafe; Value = "Safe" },
            @{ Label = $ui.FieldPoolAll; Value = "All" }
        )
        # Six listes partagent exactement le meme triplet de modes.
        foreach ($comboMode in @($evoModeCombo, $giftModeCombo, $tradeModeCombo, $staticEncounterCombo, $grassEncounterCombo, $undergroundModeCombo)) {
            Set-LocalizedComboItems -Combo $comboMode -Items @(
                @{ Label = $ui.ModeRandom; Value = "Random" },
                @{ Label = $ui.ModeSimilarBST; Value = "SimilarBST" },
                @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
            )
        }
        Set-LocalizedComboItems -Combo $npcGiftItemCombo -Items @(
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" },
            @{ Label = $ui.NpcGiftShuffle; Value = "Shuffle" },
            @{ Label = $ui.DrawRandom; Value = "Random" }
        )
        Set-LocalizedComboItems -Combo $overworldHitboxCombo -Items @(
            @{ Label = $ui.HitboxNone; Value = "0" },
            @{ Label = $ui.HitboxColossal; Value = "250" },
            @{ Label = $ui.HitboxVeryLarge; Value = "200" },
            @{ Label = $ui.HitboxLarge; Value = "150" },
            @{ Label = $ui.HitboxCompact; Value = "100" }
        )
        $overworldHitboxLabel.Text = $ui.Labels.OverworldVisibleMaxHitbox
        Set-LocalizedComboItems -Combo $overworldPoolCombo -Items @(
            @{ Label = $ui.OverworldPoolAll; Value = "All" },
            @{ Label = $ui.OverworldPoolVanilla; Value = "Vanilla" },
            @{ Label = $ui.OverworldPoolUnusual; Value = "UnusualOnly" }
        )
        $overworldPoolLabel.Text = $ui.Labels.OverworldVisiblePoolMode
        Set-LocalizedComboItems -Combo $liveVisibleModeCombo -Items @(
            @{ Label = $ui.ModeVanillaGame; Value = "Vanilla" },
            @{ Label = $ui.LiveRandomSpawn; Value = "Random" },
            @{ Label = $ui.LiveStableZone; Value = "Zone" },
            @{ Label = $ui.LiveStableGlobal; Value = "Global" },
            @{ Label = $ui.LiveDiscovery; Value = "Decouverte" },
            @{ Label = $ui.LiveDiscoveryRandom; Value = "DecouverteRandom" }
        )
        Set-LocalizedComboItems -Combo $liveBattleModeCombo -Items @(
            @{ Label = $ui.ModeVanillaGame; Value = "Vanilla" },
            @{ Label = $ui.LiveRandomBattle; Value = "Random" },
            @{ Label = $ui.LiveStableZone; Value = "Zone" },
            @{ Label = $ui.LiveStableGlobal; Value = "Global" }
        )
        Set-LocalizedComboItems -Combo $expCurveCombo -Items @(
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" },
            @{ Label = $ui.ExpCurveFast; Value = "Fast" },
            @{ Label = $ui.ExpCurveMedium; Value = "MediumFast" },
            @{ Label = $ui.ExpCurveSlow; Value = "Slow" }
        )
        Set-LocalizedComboItems -Combo $tmMoveCombo -Items @(
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" },
            @{ Label = $ui.TmShuffle; Value = "Shuffle" },
            @{ Label = $ui.DrawRandom; Value = "Random" }
        )
        Set-LocalizedComboItems -Combo $tmCompatCombo -Items @(
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" },
            @{ Label = $ui.CompatHalf; Value = "Random" },
            @{ Label = $ui.CompatSameType; Value = "SameType" },
            @{ Label = $ui.CompatFull; Value = "Full" }
        )
        Set-LocalizedComboItems -Combo $tutorCompatCombo -Items @(
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" },
            @{ Label = $ui.CompatHalf; Value = "Random" },
            @{ Label = $ui.CompatFull; Value = "Full" }
        )

        if ($script:LastDetailsDescription) {
            $detailsBox.Text = Get-LocalizedDescriptionText -Description $script:LastDetailsDescription
        } elseif ([string]::IsNullOrWhiteSpace($detailsBox.Text) -or
            $detailsBox.Text -eq (Get-UiStrings -Language "fr").Labels.DetailsDefault -or
            $detailsBox.Text -eq (Get-UiStrings -Language "en").Labels.DetailsDefault) {
            $detailsBox.Text = $ui.Labels.DetailsDefault
        }
        if ([string]::IsNullOrWhiteSpace($statusBox.Text)) {
            $statusBox.Text = $ui.Labels.StatusDefault
        }

        # EN DERNIER, et pas au milieu. Le rail recopie le texte des onglets et
        # les cartes recopient celui de leur etiquette-titre : appeles avant que
        # tout soit traduit, ils figeaient la langue precedente. Trois onglets
        # sur neuf (Rencontres, Aide, Nettoyage) sont renommes plus bas dans
        # cette fonction, d'ou un rail moitie francais moitie anglais, et des
        # titres de cartes restes dans l'autre langue.
        Update-PfRailLabels
        Update-PfCards
        $script:ApplyingUiLanguage = $false
    }

    function Update-InstallationUi {
        $gameVersion = Get-SourceGameVersion -RomfsRoot $controls.Source.Text
        $modName = Get-NormalizedModName -ModName $controls.EdenModName.Text
        $ui = Get-UiStrings -Language $script:UiLanguage
        $targetMap = @{}
        foreach ($target in @(Get-EmulatorInstallTargets -GameVersion $gameVersion -ModName $modName)) {
            $targetMap[[string]$target.Key] = $target
        }

        foreach ($pair in @(
            @{ Control = $controls.InstallToRyujinx; ResetControl = $controls.ResetInstallToRyujinx; Key = "ryujinx"; Label = $ui.Labels.InstallTargetRyujinx }
        )) {
            $target = $targetMap[$pair.Key]
            $statusText = if ($target -and [bool]$target.IsDetected) {
                if ($script:UiLanguage -eq "en") { "detected" } else { "détecté" }
            } else {
                if ($script:UiLanguage -eq "en") { "not found" } else { "introuvable" }
            }
            $pair.Control.Text = ("{0} [{1}]" -f $pair.Label, $statusText)
            $pair.ResetControl.Text = $pair.Control.Text
            if ($controls.AutoInstallToEden) {
                $pair.Control.Enabled = ([bool]$controls.AutoInstallToEden.Checked -and $target -and [bool]$target.IsDetected)
            }
            if ($pair.ResetControl) {
                $pair.ResetControl.Enabled = ($target -and [bool]$target.IsDetected)
            }
        }

        $helpBox.Text = Get-RandomizerHelpText -Language $script:UiLanguage -GameVersion $gameVersion -ModName $modName -OutputRomfsRoot $controls.Output.Text
        if ([string]::IsNullOrWhiteSpace($resetStatusBox.Text)) {
            $resetStatusBox.Text = $ui.Labels.ResetDefault
        }
    }

    function Set-OptionControlsEnabled {
        param(
            [bool]$Enabled,
            [object[]]$ControlList
        )

        foreach ($control in @($ControlList)) {
            if ($null -ne $control) {
                $control.Enabled = $Enabled
            }
        }
    }

    function Update-CompatibilityUi {
        if ($script:ApplyingCompatibilityUi) {
            return
        }

        $script:ApplyingCompatibilityUi = $true
        try {
            $trainerSpeciesModeValue = Normalize-Mode (Get-ComboValue -Combo $controls.TrainerSpeciesMode)
            $trainerMoveModeValue = Normalize-Mode (Get-ComboValue -Combo $controls.TrainerMoveMode)
            $trainerItemModeValue = Normalize-Mode (Get-ComboValue -Combo $controls.TrainerItemMode)
            $forceAllTeams = [bool]$controls.ForceAllTeamsToSix.Checked
            if ($forceAllTeams -and [bool]$controls.ForceBossTeamsToSix.Checked) {
                $controls.ForceBossTeamsToSix.Checked = $false
            }

            $forceBossTeams = ([bool]$controls.ForceBossTeamsToSix.Checked -and -not $forceAllTeams)
            $teamExpansionEnabled = ($forceAllTeams -or $forceBossTeams)
            $smogonItemModeEnabled = Test-TrainerModeUsesSmogon $trainerItemModeValue
            $itemRandomEnabled = ($trainerItemModeValue -in @("randomwhenpresent", "forceall"))
            $smogonMoveFallbackEnabled = Test-TrainerModeUsesSmogon $trainerMoveModeValue
            $speciesRandomEnabled = ($trainerSpeciesModeValue -ne "unchanged")
            $addedSlotSpeciesChoiceEnabled = ($teamExpansionEnabled -and -not $speciesRandomEnabled)
            $duplicateModeUseful = ($speciesRandomEnabled -or $itemRandomEnabled -or $smogonItemModeEnabled -or $teamExpansionEnabled)

            if ($smogonItemModeEnabled) {
                [void](Set-ComboValue -Combo $controls.TrainerItemPoolMode -Value "Battle")
            }

            Set-OptionControlsEnabled -Enabled $itemRandomEnabled -ControlList @($trainerItemPoolLabel, $trainerItemPoolCombo)
            Set-OptionControlsEnabled -Enabled $smogonMoveFallbackEnabled -ControlList @($trainerSmogonMoveFallbackLabel, $trainerSmogonMoveFallbackCombo)
            Set-OptionControlsEnabled -Enabled $addedSlotSpeciesChoiceEnabled -ControlList @($trainerAddedSlotSpeciesLabel, $trainerAddedSlotSpeciesCombo)
            Set-OptionControlsEnabled -Enabled $duplicateModeUseful -ControlList @($trainerDuplicateModeLabel, $trainerDuplicateModeCombo)
            Set-OptionControlsEnabled -Enabled $speciesRandomEnabled -ControlList @($controls.TrainerTypeThemed)
            Set-OptionControlsEnabled -Enabled ($speciesRandomEnabled -or $addedSlotSpeciesChoiceEnabled) -ControlList @($controls.AllowLegendaryTrainers)
            Set-OptionControlsEnabled -Enabled (-not $forceAllTeams) -ControlList @($controls.ForceBossTeamsToSix)
            Set-OptionControlsEnabled -Enabled $forceBossTeams -ControlList @($bossTeamsScopeLabel, $bossTeamsScopeCombo, $bossTargetsBox)

            # La stabilite des rencontres en herbe n'a de sens qu'avec un tirage
            # stable. On grise la liste dans les deux autres cas plutot que de la
            # laisser accepter un choix que le generateur ecrasera.
            $encounterDrawModeValue = Get-NormalizedEncounterDrawMode -Value (Get-ComboValue -Combo $controls.EncounterDrawMode) -LegacyVisibleBehavior (Get-ComboValue -Combo $controls.VisibleEncounterBehavior)
            Set-OptionControlsEnabled -Enabled ($encounterDrawModeValue -eq "SlotParEspece") -ControlList @($grassStableMappingLabel, $grassStableMappingCombo)

            if (-not $forceBossTeams) {
                $bossTargetsBox.Text = if ($script:UiLanguage -eq "en") {
                    "Enable boss teams at 6 Pokemon to use this target list."
                } else {
                    "Coche « Mettre certains boss à 6 Pokémon » pour que cette liste serve à quelque chose."
                }
            } else {
                $bossTargetsBox.Text = Get-BossTrainerUniqueNamesText -Language $script:UiLanguage -Scope (Get-ComboValue -Combo $controls.BossTeamsToSixScope)
            }

            Update-InstallationUi
        } finally {
            $script:ApplyingCompatibilityUi = $false
        }
    }

    $uiLangCombo.Add_SelectedIndexChanged({
        Apply-UiLanguage -Language (Get-ComboValue -Combo $controls.UiLanguage)
        Update-InstallationUi
        Update-CompatibilityUi
        Bring-TopChromeToFront
    })

    $themeCombo.Add_SelectedIndexChanged({
        Apply-GuiTheme -Root $form -Theme (Get-ComboValue -Combo $controls.GuiTheme)
        Bring-TopChromeToFront
    })

    $bossTeamsScopeCombo.Add_SelectedIndexChanged({
        if (-not $script:ApplyingUiLanguage) {
            $bossTargetsBox.Text = Get-BossTrainerUniqueNamesText -Language $script:UiLanguage -Scope (Get-ComboValue -Combo $controls.BossTeamsToSixScope)
        }
    })

    foreach ($combo in @(
        $trainerSpeciesCombo,
        $trainerMoveCombo,
        $trainerItemCombo,
        $trainerAddedSlotSpeciesCombo,
        $trainerDuplicateModeCombo,
        $encounterDrawModeCombo,
        $visibleBehaviorCombo
    )) {
        $combo.Add_SelectedIndexChanged({ Update-CompatibilityUi })
    }

    foreach ($checkBox in @(
        $controls.ForceAllTeamsToSix,
        $controls.ForceBossTeamsToSix,
        $controls.AutoInstallToEden
    )) {
        $checkBox.Add_CheckedChanged({ Update-CompatibilityUi })
    }

    $controls.Source.Add_TextChanged({ Update-InstallationUi; Update-CompatibilityUi })
    $controls.Output.Add_TextChanged({ Update-InstallationUi })
    $controls.EdenModName.Add_TextChanged({ Update-InstallationUi; Update-CompatibilityUi })

    $validateBuildButton.Add_Click({
        try {
            Disable-RemovedBuildOptions -Controls $controls
            $validation = Test-GuiBuildConfiguration -Controls $controls -Language $script:UiLanguage
            $statusBox.Text = Format-GuiBuildValidationResult -Validation $validation -Language $script:UiLanguage
            if ($validation.Errors.Count -gt 0) {
                [void](Confirm-GuiBuildValidationResult -Owner $form -Validation $validation -Language $script:UiLanguage -ConfirmWarnings $false)
            } elseif ($validation.Warnings.Count -gt 0) {
                $title = if ($script:UiLanguage -eq "en") { "Config warnings" } else { "Avertissements config" }
                [void][System.Windows.Forms.MessageBox]::Show($form, $statusBox.Text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            } else {
                $title = if ($script:UiLanguage -eq "en") { "Config OK" } else { "Config OK" }
                [void][System.Windows.Forms.MessageBox]::Show($form, $statusBox.Text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } catch {
            $statusBox.Text = "Erreur: $($_.Exception.Message)"
        }
    })

    $buildSummaryButton.Add_Click({
        try {
            Disable-RemovedBuildOptions -Controls $controls
            $validation = Test-GuiBuildConfiguration -Controls $controls -Language $script:UiLanguage
            $statusBox.Text = Format-GuiBuildValidationResult -Validation $validation -Language $script:UiLanguage
            if ($validation.Errors.Count -gt 0) {
                [void](Confirm-GuiBuildValidationResult -Owner $form -Validation $validation -Language $script:UiLanguage -ConfirmWarnings $false)
                return
            }
            $summary = Get-GuiBuildSummaryText -Controls $controls -Validation $validation -Language $script:UiLanguage
            $statusBox.Text = $summary
            [void](Show-GuiBuildSummaryDialog -Owner $form -SummaryText $summary -Language $script:UiLanguage -ConfirmGeneration $false)
        } catch {
            $statusBox.Text = "Erreur: $($_.Exception.Message)"
        }
    })

    Apply-UiLanguage -Language $script:UiLanguage
    Update-InstallationUi
    Update-CompatibilityUi
    Apply-GuiTheme -Root $form -Theme $script:GuiTheme
    Bring-TopChromeToFront
    $form.Add_Shown({ Bring-TopChromeToFront })

    $exportPresetButton.Add_Click({
        try {
            $dialog = New-Object System.Windows.Forms.SaveFileDialog
            $dialog.Filter = "JSON preset (*.json)|*.json|All files (*.*)|*.*"
            $dialog.Title = if ($script:UiLanguage -eq "en") { "Export randomizer preset" } else { "Exporter le preset du randomizer" }
            $dialog.FileName = "PokeFeurRandomSWSH-preset.json"
            if ($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK) {
                return
            }

            $preset = Get-GuiPresetFromControls -Controls $controls
            $json = $preset | ConvertTo-Json -Depth 8
            [IO.File]::WriteAllText($dialog.FileName, $json, [Text.UTF8Encoding]::new($false))
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Preset exported: $($dialog.FileName)`r`nLocal ROMFS/ExeFS/output paths are not included, so the preset can be shared safely."
            } else {
                "Preset exporte: $($dialog.FileName)`r`nLes chemins locaux ROMFS/ExeFS/sortie ne sont pas inclus, donc le preset peut etre partage proprement."
            }
        } catch [System.Management.Automation.PipelineStoppedException] {
            $statusBox.Text = if ($script:UiLanguage -eq "en") { "Preset export cancelled." } else { "Export preset annule." }
        } catch {
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Preset export error: $($_.Exception.Message)"
            } else {
                "Erreur export preset: $($_.Exception.Message)"
            }
        }
    })

    $importPresetButton.Add_Click({
        try {
            $dialog = New-Object System.Windows.Forms.OpenFileDialog
            $dialog.Filter = "JSON preset (*.json)|*.json|All files (*.*)|*.*"
            $dialog.Title = if ($script:UiLanguage -eq "en") { "Import randomizer preset" } else { "Importer un preset du randomizer" }
            if ($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK) {
                return
            }

            $preset = Get-Content -LiteralPath $dialog.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
            # Un preset ne doit JAMAIS toucher aux chemins locaux. Sans ce verrou,
            # appliquer GameVersion declenchait la remise a zero des chemins.
            $script:SuppressGameVersionPathReset = $true
            try {
                $applied = Set-GuiControlsFromPreset -Controls $controls -Preset $preset
            } finally {
                $script:SuppressGameVersionPathReset = $false
            }
            Disable-RemovedBuildOptions -Controls $controls
            Apply-UiLanguage -Language (Get-ComboValue -Combo $controls.UiLanguage)
            Update-InstallationUi
            Update-CompatibilityUi
            Apply-GuiTheme -Root $form -Theme (Get-ComboValue -Combo $controls.GuiTheme)
            Bring-TopChromeToFront
            $skippedPaths = @($script:LastPresetSkippedPathOptions)
            $pathNote = ""
            if ($skippedPaths.Count -gt 0) {
                $pathNote = if ($script:UiLanguage -eq "en") {
                    "`r`nLocal paths ignored from preset: $($skippedPaths -join '; ')"
                } else {
                    "`r`nChemins locaux ignores depuis le preset: $($skippedPaths -join '; ')"
                }
            }
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Preset imported: $($dialog.FileName)`r`nOptions applied: $applied$pathNote"
            } else {
                "Preset importe: $($dialog.FileName)`r`nOptions appliquees: $applied$pathNote"
            }
        } catch [System.Management.Automation.PipelineStoppedException] {
            $statusBox.Text = if ($script:UiLanguage -eq "en") { "Preset import cancelled." } else { "Import preset annule." }
        } catch {
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Preset import error: $($_.Exception.Message)"
            } else {
                "Erreur import preset: $($_.Exception.Message)"
            }
        }
    })

    $resetButton.Add_Click({
        $previousInstallToRyujinx = $script:InstallToRyujinx
        try {
            $script:InstallToRyujinx = [bool]$controls.ResetInstallToRyujinx.Checked
            if (@(Get-RequestedEmulatorKeys).Count -lt 1) {
                throw $(if ($script:UiLanguage -eq "en") { "Select at least one emulator target for reset." } else { "Coche au moins une cible émulateur pour le reset." })
            }

            $gameVersion = Get-SourceGameVersion -RomfsRoot $controls.Source.Text
            $resetResults = @(Reset-SelectedEmulatorInstallations -GameVersion $gameVersion -ModName $controls.EdenModName.Text)
            if ($script:UiLanguage -eq "en") {
                $lines = @("Reset finished.")
                foreach ($entry in $resetResults) {
                    if ([string]::IsNullOrWhiteSpace([string]$entry.Error)) {
                        $lines += ("{0}: mod removed={1}, config removed={2}" -f $entry.Emulator, $entry.RemovedMod, $entry.RemovedConfig)
                        if (-not [string]::IsNullOrWhiteSpace([string]$entry.Note)) {
                            $lines += ("{0}: {1}" -f $entry.Emulator, [string]$entry.Note)
                        }
                    } else {
                        $lines += ("{0}: {1}" -f $entry.Emulator, $entry.Error)
                    }
                }
                $resetStatusBox.Text = ($lines -join [Environment]::NewLine)
            } else {
                $lines = @("Reset termine.")
                foreach ($entry in $resetResults) {
                    if ([string]::IsNullOrWhiteSpace([string]$entry.Error)) {
                        $lines += ("{0}: mod supprime={1}, config supprimee={2}" -f $entry.Emulator, $entry.RemovedMod, $entry.RemovedConfig)
                        if (-not [string]::IsNullOrWhiteSpace([string]$entry.Note)) {
                            $lines += ("{0}: {1}" -f $entry.Emulator, [string]$entry.Note)
                        }
                    } else {
                        $lines += ("{0}: {1}" -f $entry.Emulator, $entry.Error)
                    }
                }
                $resetStatusBox.Text = ($lines -join [Environment]::NewLine)
            }
        } catch {
            if ($script:UiLanguage -eq "en") {
                $resetStatusBox.Text = ("Error: {0}" -f $_.Exception.Message)
            } else {
                $resetStatusBox.Text = ("Erreur: {0}" -f $_.Exception.Message)
            }
        } finally {
            $script:InstallToRyujinx = $previousInstallToRyujinx
            Update-InstallationUi
        }
    })

    $runButton.Add_Click({
        try {
            $ui = Get-UiStrings -Language $script:UiLanguage
            $runButton.Enabled = $false
            $statusBox.Text = if ($script:UiLanguage -eq "en") { "Validating configuration..." } else { "Validation de la configuration..." }
            $form.Refresh()

            Disable-RemovedBuildOptions -Controls $controls
            $validation = Test-GuiBuildConfiguration -Controls $controls -Language $script:UiLanguage
            $statusBox.Text = Format-GuiBuildValidationResult -Validation $validation -Language $script:UiLanguage
            if (-not (Confirm-GuiBuildValidationResult -Owner $form -Validation $validation -Language $script:UiLanguage -ConfirmWarnings $true)) {
                return
            }

            $summary = Get-GuiBuildSummaryText -Controls $controls -Validation $validation -Language $script:UiLanguage
            $statusBox.Text = $summary
            if (-not (Show-GuiBuildSummaryDialog -Owner $form -SummaryText $summary -Language $script:UiLanguage -ConfirmGeneration $true)) {
                return
            }

            $statusBox.Text = $ui.Labels.StatusRunning
            $form.Refresh()

            $seedText = ([string]$controls.Seed.Text).Trim()
            $parsedSeed = 0L
            if (-not [long]::TryParse($seedText, [ref]$parsedSeed)) {
                throw $ui.Labels.SeedError
            }

            $script:SourceRomfs = $controls.Source.Text
            $script:SourceExefs = $controls.SourceExefs.Text
            $script:OutputRomfs = $controls.Output.Text
            $script:GameVersion = Get-ComboValue -Combo $controls.GameVersion
            $script:Seed = Resolve-SeedValue -SeedValue $parsedSeed
            $script:UiLanguage = Get-ComboValue -Combo $controls.UiLanguage
            $script:ReportLanguage = Get-ComboValue -Combo $controls.ReportLanguage
            $script:DisableExpShare = [switch]$controls.DisableExpShare.Checked
            $script:EarlyBike = [switch]$controls.EarlyBike.Checked
            $script:RuntimePcControls = [bool]$controls.RuntimePcControls.Checked
            $script:DynamicExpLevelCap = [switch]$controls.DynamicExpLevelCap.Checked
            $script:StrictBossMaxLevelCap = [switch]$controls.StrictBossMaxLevelCap.Checked
            $script:MainStorySoftLevelCap = [switch]$controls.MainStorySoftLevelCap.Checked
            $script:GymLeagueStoryLevelCap = [switch]$controls.GymLeagueStoryLevelCap.Checked
            $script:StoryMajorBattleOrderLevelCap = [switch]$controls.StoryMajorBattleOrderLevelCap.Checked
            $script:AutoInstallToEden = [switch]$controls.AutoInstallToEden.Checked
            $script:EdenModName = $controls.EdenModName.Text
            $script:InstallToRyujinx = [bool]$controls.InstallToRyujinx.Checked
            $script:ExportEncounterZoneReport = [bool]$controls.ExportEncounterZoneReport.Checked
            $script:TrainerSpeciesMode = Get-ComboValue -Combo $controls.TrainerSpeciesMode
            $script:TrainerMoveMode = Get-ComboValue -Combo $controls.TrainerMoveMode
            $script:TrainerSmogonMoveFallbackMode = Get-ComboValue -Combo $controls.TrainerSmogonMoveFallbackMode
            $script:TrainerItemMode = Get-ComboValue -Combo $controls.TrainerItemMode
            $script:TrainerItemPoolMode = Get-ComboValue -Combo $controls.TrainerItemPoolMode
            $script:TrainerAddedSlotSpeciesMode = Get-ComboValue -Combo $controls.TrainerAddedSlotSpeciesMode
            $script:TrainerDuplicateMode = Get-ComboValue -Combo $controls.TrainerDuplicateMode
            $script:TrainerAbilityMode = Get-ComboValue -Combo $controls.TrainerAbilityMode
            $script:TrainerIVMode = Get-ComboValue -Combo $controls.TrainerIVMode
            $script:TrainerEVMode = Get-ComboValue -Combo $controls.TrainerEVMode
            $script:TrainerNatureMode = Get-ComboValue -Combo $controls.TrainerNatureMode
            $script:RandomizeTrainerNatures = [switch]((Get-EffectiveTrainerNatureMode -Mode $script:TrainerNatureMode -LegacyRandomize $false) -eq "random")
            $script:TrainerLevelMultiplier = Convert-GuiDoubleText -Text $controls.TrainerLevelMultiplier.Text -Label $ui.Labels.TrainerLevel -Language $script:UiLanguage
            $script:TrainerTeamMin = [int]$controls.TrainerTeamMin.Text
            $script:TrainerTeamMax = [int]$controls.TrainerTeamMax.Text
            $script:TrainerTypeThemed = [switch]$controls.TrainerTypeThemed.Checked
            $script:TrainerShinyChancePercent = Convert-GuiDoubleText -Text $controls.TrainerShinyChancePercent.Text -Label $ui.Labels.TrainerShinyChance -Language $script:UiLanguage
            $script:ForceTrainerFullyEvolved = [switch]$controls.ForceTrainerFullyEvolved.Checked
            $script:TrainerFullyEvolvedLevel = [int]$controls.TrainerFullyEvolvedLevel.Text
            $script:MaxTrainerAI = [switch]$controls.MaxTrainerAI.Checked
            $script:TrainerDynamaxLevelMode = Get-ComboValue -Combo $controls.TrainerDynamaxLevelMode
            $script:ForceTrainerCanDynamax = [switch]$controls.ForceTrainerCanDynamax.Checked
            $script:ForceAllTeamsToSix = [switch]$controls.ForceAllTeamsToSix.Checked
            $script:ForceBossTeamsToSix = [bool]$controls.ForceBossTeamsToSix.Checked
            $script:BossTeamsToSixScope = Get-ComboValue -Combo $controls.BossTeamsToSixScope
            $script:AllowLegendaryTrainers = [switch]$controls.AllowLegendaryTrainers.Checked
            $script:TrainerExtraPokemonBoss = ConvertTo-BoundedInt -Text $controls.TrainerExtraPokemonBoss.Text -Default 0 -Minimum 0 -Maximum 5
            $script:TrainerExtraPokemonImportant = ConvertTo-BoundedInt -Text $controls.TrainerExtraPokemonImportant.Text -Default 0 -Minimum 0 -Maximum 5
            $script:TrainerExtraPokemonRegular = ConvertTo-BoundedInt -Text $controls.TrainerExtraPokemonRegular.Text -Default 0 -Minimum 0 -Maximum 5
            $script:TrainerSpecialRuleScope = Get-ComboValue -Combo $controls.TrainerSpecialRuleScope
            $script:TrainerLegendaryPolicy = Get-ComboValue -Combo $controls.TrainerLegendaryPolicy
            $script:TrainerMinBaseStatTotal = ConvertTo-BoundedInt -Text $controls.TrainerMinBaseStatTotal.Text -Default 0 -Minimum 0 -Maximum 1530
            $script:TrainerForceDiverseTypes = [string](Get-ComboValue -Combo $controls.TrainerForceDiverseTypes)
            $script:TypeMode = Get-ComboValue -Combo $controls.TypeMode
            $script:TypesMonotypeOnly = [switch]$controls.TypesMonotypeOnly.Checked
            $script:AbilityMode = Get-ComboValue -Combo $controls.AbilityMode
            $script:AllowWonderGuard = [switch]$controls.AllowWonderGuard.Checked
            $script:StatMode = Get-ComboValue -Combo $controls.StatMode
            $script:ExpYieldMultiplier = Convert-GuiDoubleText -Text $controls.ExpYieldMultiplier.Text -Label $ui.Labels.ExpYieldMultiplier -Language $script:UiLanguage
            $script:ForceOneExpYield = [switch]$controls.ForceOneExpYield.Checked
            $script:RandomizeMoveTypes = [switch]$controls.RandomizeMoveTypes.Checked
            $script:RandomizeMovePower = [switch]$controls.RandomizeMovePower.Checked
            $script:MovePowerMin = [int]$controls.MovePowerMin.Text
            $script:MovePowerMax = [int]$controls.MovePowerMax.Text
            $script:RandomizeMovePP = [switch]$controls.RandomizeMovePP.Checked
            $script:MovePPMin = [int]$controls.MovePPMin.Text
            $script:MovePPMax = [int]$controls.MovePPMax.Text
            $script:RandomizeMoveAccuracy = [switch]$controls.RandomizeMoveAccuracy.Checked
            $script:MoveAccuracyMin = [int]$controls.MoveAccuracyMin.Text
            $script:MoveAccuracyMax = [int]$controls.MoveAccuracyMax.Text
            $script:RandomizeMoveCategory = [switch]$controls.RandomizeMoveCategory.Checked
            $script:RandomizePickupItems = [switch]$controls.RandomizePickupItems.Checked
            $script:RandomizeShopItems = [switch]$controls.RandomizeShopItems.Checked
            # Une entree « random:min:max » porte le mode ET ses bornes : le
            # combo garde une seule valeur, et l'interface n'a pas besoin de
            # deux champs de saisie supplementaires.
            $valeurPrix = [string](Get-ComboValue -Combo $controls.ShopPriceMultiplier)
            if ($valeurPrix -match '^random:(\d+):(\d+)$') {
                $script:ShopPriceMode = "Random"
                $script:ShopPriceMin = [int]$Matches[1]
                $script:ShopPriceMax = [int]$Matches[2]
                $script:ShopPriceMultiplier = "1"
            } else {
                $script:ShopPriceMode = "Multiplier"
                $script:ShopPriceMultiplier = $valeurPrix
            }
            $script:ModOverworldShiny = [switch]$controls.ModOverworldShiny.Checked
            $script:OverworldShinyBoostPercent = ConvertTo-BoundedInt -Text $controls.OverworldShinyBoostPercent.Text -Default 0 -Minimum 0 -Maximum 100
            $script:ModUncapLevel = [switch]$controls.ModUncapLevel.Checked
            $script:ModUnderworld = [switch]$controls.ModUnderworld.Checked
            $script:ModExtendedFollowing = [switch]$controls.ModExtendedFollowing.Checked
            $script:ModGlimwoodOverworld = [switch]$controls.ModGlimwoodOverworld.Checked
            $script:GlimwoodMaxSpawns = ConvertTo-BoundedInt -Text $controls.GlimwoodMaxSpawns.Text -Default 5 -Minimum 1 -Maximum 20
            $script:GenerationFilterVisible = [string]$controls.GenerationFilterVisible.Text
            $script:GenerationFilterBattle = [string]$controls.GenerationFilterBattle.Text
            $script:GenerationFilterGifts = [string]$controls.GenerationFilterGifts.Text
            $script:GenerationFilterTrainers = [string]$controls.GenerationFilterTrainers.Text
            $script:EvolutionMinBstGain = ConvertTo-BoundedInt -Text $controls.EvolutionMinBstGain.Text -Default -1 -Minimum -1 -Maximum 600
            $script:ShopItemMode = [string](Get-ComboValue -Combo $controls.ShopItemMode)
            $script:TrainerBagItemMode = [string](Get-ComboValue -Combo $controls.TrainerBagItemMode)
            $script:OverworldModelSafeEncounters = [bool]$controls.OverworldModelSafeEncounters.Checked
            $script:WriteInstallationPackage = [bool]$controls.WriteInstallationPackage.Checked
            $script:StrictDataFiles = [switch]$controls.StrictDataFiles.Checked
            $script:ModFishingTweaks = [switch]$controls.ModFishingTweaks.Checked
            $script:ModSynchroMode = [switch]$controls.ModSynchroMode.Checked
            $script:ModCameraTweaks = [switch]$controls.ModCameraTweaks.Checked
            $script:ModFreecam = [switch]$controls.ModFreecam.Checked
            $script:ModDexAnimations = [switch]$controls.ModDexAnimations.Checked
            $script:FollowEvolutionsForTypes = [switch]$controls.FollowEvolutionsForTypes.Checked
            $script:FollowEvolutionsForAbilities = [switch]$controls.FollowEvolutionsForAbilities.Checked
            $script:EvolutionForceGrowth = [switch]$controls.EvolutionForceGrowth.Checked
            $script:EvolutionLimitToThreeStages = [switch]$controls.EvolutionLimitToThreeStages.Checked
            $script:StarterMinBaseStatTotal = ConvertTo-BoundedInt -Text $controls.StarterMinBaseStatTotal.Text -Default 0 -Minimum 0 -Maximum 1530
            $script:StarterMaxBaseStatTotal = ConvertTo-BoundedInt -Text $controls.StarterMaxBaseStatTotal.Text -Default 0 -Minimum 0 -Maximum 1530
            $script:EvolutionSameType = [switch]$controls.EvolutionSameType.Checked
            $script:MinimumCatchRate = ConvertTo-BoundedInt -Text $controls.MinimumCatchRate.Text -Default 0 -Minimum 0 -Maximum 255
            $script:ExpCurveMode = [string](Get-ComboValue -Combo $controls.ExpCurveMode)
            $script:TmCompatibilityMode = [string](Get-ComboValue -Combo $controls.TmCompatibilityMode)
            $script:TutorCompatibilityMode = [string](Get-ComboValue -Combo $controls.TutorCompatibilityMode)
            $script:TmMoveMode = [string](Get-ComboValue -Combo $controls.TmMoveMode)
            $script:LearnsetMoveMode = [string](Get-ComboValue -Combo $controls.LearnsetMoveMode)
            $script:NpcGiftItemMode = [string](Get-ComboValue -Combo $controls.NpcGiftItemMode)
            $script:RandomizeWildHeldItems = [switch]$controls.RandomizeWildHeldItems.Checked
            $script:RandomizeFieldItems = [switch]$controls.RandomizeFieldItems.Checked
            $script:RandomizeHiddenItems = [switch]$controls.RandomizeHiddenItems.Checked
            $script:FieldItemPoolMode = [string](Get-ComboValue -Combo $controls.FieldItemPoolMode)
            $script:RandomizeTechnicalRecords = [switch]$controls.RandomizeTechnicalRecords.Checked
            $script:EvolutionMode = Get-ComboValue -Combo $controls.EvolutionMode
            $script:AllowLegendaryEvolutions = [switch]$controls.AllowLegendaryEvolutions.Checked
            $script:NormalizeFriendshipEvolutions = [bool]$controls.NormalizeFriendshipEvolutions.Checked
            $script:FriendshipEvolutionLevel = [int]$controls.FriendshipEvolutionLevel.Text
            $script:NormalizeTradeEvolutions = [bool]$controls.NormalizeTradeEvolutions.Checked
            $script:TradeEvolutionLevel = [int]$controls.TradeEvolutionLevel.Text
            $script:NormalizeSpecialEvolutions = [bool]$controls.NormalizeSpecialEvolutions.Checked
            $script:SpecialEvolutionLevel = [int]$controls.SpecialEvolutionLevel.Text
            $script:GiftMode = Get-ComboValue -Combo $controls.GiftMode
            $script:StarterMode = Get-ComboValue -Combo $controls.StarterMode
            $script:Starter1 = $controls.Starter1.Text
            $script:Starter2 = $controls.Starter2.Text
            $script:Starter3 = $controls.Starter3.Text
            $script:PatchStarterRelatedTrainers = [bool]$controls.PatchStarterRelatedTrainers.Checked
            $script:AllowLegendaryGifts = [switch]$controls.AllowLegendaryGifts.Checked
            $script:TradeMode = Get-ComboValue -Combo $controls.TradeMode
            $script:AllowLegendaryTrades = [switch]$controls.AllowLegendaryTrades.Checked
            $script:StaticEncounterMode = Get-ComboValue -Combo $controls.StaticEncounterMode
            $script:AllowLegendaryStaticEncounters = [switch]$controls.AllowLegendaryStaticEncounters.Checked
            $script:StaticEncounterStableMapping = Get-ComboValue -Combo $controls.StaticEncounterStableMapping
            $script:GrassEncounterMode = Get-ComboValue -Combo $controls.GrassEncounterMode
            $script:AllowLegendaryGrassEncounters = [switch]$controls.AllowLegendaryGrassEncounters.Checked
            $script:GrassEncounterStableMapping = Get-ComboValue -Combo $controls.GrassEncounterStableMapping
            $script:VisibleEncounterBehavior = Get-ComboValue -Combo $controls.VisibleEncounterBehavior
            $script:EncounterDrawMode = Get-ComboValue -Combo $controls.EncounterDrawMode
            $script:LiveVisibleMode = Get-ComboValue -Combo $controls.LiveVisibleMode
            $script:LiveBattleMode = Get-ComboValue -Combo $controls.LiveBattleMode
            $script:AllowLegendaryLiveVisible = [switch]$controls.AllowLegendaryLiveVisible.Checked
            $script:AllowLegendaryLiveBattle = [switch]$controls.AllowLegendaryLiveBattle.Checked
            $script:LiveGenerationFilter = [string]$controls.LiveGenerationFilter.Text
            $script:OverworldVisiblePoolMode = Get-ComboValue -Combo $controls.OverworldVisiblePoolMode
            $script:OverworldVisibleMaxHitbox = ConvertTo-BoundedInt -Text (Get-ComboValue -Combo $controls.OverworldVisibleMaxHitbox) -Minimum 0 -Maximum 1000 -Default 0
            $script:WildLevelPercent = ConvertTo-BoundedInt -Text $controls.WildLevelPercent.Text -Default 0 -Minimum -100 -Maximum 155
            $script:UndergroundMode = Get-ComboValue -Combo $controls.UndergroundMode
            $script:AllowLegendaryUnderground = [switch]$controls.AllowLegendaryUnderground.Checked

            $progressLines = New-Object System.Collections.Generic.List[string]
            $progressCallback = {
                param([string]$Message)
                $progressLines.Add($Message)
                while ($progressLines.Count -gt 10) {
                    $progressLines.RemoveAt(0)
                }
                $statusBox.Text = ($progressLines -join [Environment]::NewLine)
                $statusBox.SelectionStart = $statusBox.Text.Length
                $statusBox.ScrollToCaret()
                [System.Windows.Forms.Application]::DoEvents()
            }

            $result = Invoke-Randomization -SourceRomfsRoot $controls.Source.Text -SourceExefsRoot $controls.SourceExefs.Text -OutputRomfsRoot $controls.Output.Text -ProgressCallback $progressCallback

            if ($script:UiLanguage -eq "en") {
                $statusBox.Text = @"
Done.
Output: $($result.Output)
Seed: $($result.Seed)
Personal edited: $($result.PersonalEntriesEdited)
EXP yields edited: $($result.ExpYieldsEdited)
Moves edited: $($result.MovesEdited)
Move types edited: $($result.MoveTypesEdited)
Move powers edited: $($result.MovePowersEdited)
Move PP edited: $($result.MovePPEdited)
Move accuracy edited: $($result.MoveAccuracyEdited)
Move categories edited: $($result.MoveCategoriesEdited)
Pickup items edited: $($result.PickupItemsEdited)
Shop items edited: $($result.ShopItemsEdited)
TM/TR item IDs edited: $($result.TechnicalRecordsEdited)
Trainers edited: $($result.TrainersEdited)
Trainer Pokemon processed: $($result.TrainerPokemonProcessed)
Boss teams expanded to 6: $($result.BossTeamsExpanded)
Boss teams normalized to strict cap: $($result.BossTeamsLevelNormalized)
Trainer shinies forced: $($result.TrainerShiniesForced)
Trainer Pokemon force-evolved: $($result.TrainerSpeciesForceEvolved)
Type-themed trainer teams: $($result.TrainerTypeThemedTrainers)
Trainer AI maxed: $($result.TrainerAIMaxed)
Trainer Dynamax levels edited: $($result.TrainerDynamaxLevelsEdited)
Trainer CanDynamax flags forced: $($result.TrainerDynamaxFlagsForced)
Trainer detailed changes logged: $($result.TrainerChangesLogged)
Evolutions edited: $($result.EvolutionsEdited)
Friendship evolutions normalized: $($result.FriendshipEvolutionsNormalized)
Trade evolutions normalized: $($result.TradeEvolutionsNormalized)
Special evolutions normalized: $($result.SpecialEvolutionsNormalized)
Gifts edited: $($result.GiftsEdited)
Starters edited: $($result.StartersEdited)
Starter-related trainer files patched: $($result.StarterRelatedTrainerFilesEdited)
Starter-related trainer slots patched: $($result.StarterRelatedTrainerSlotsEdited)
In-game trade slots edited: $($result.TradeSpeciesSlotsEdited)
Static encounters edited: $($result.StaticEncountersEdited)
Tall grass slots edited: $($result.GrassEncounterSlotsEdited)
Underground slots edited: $($result.UndergroundSpeciesSlotsEdited)
Wild detailed changes logged: $($result.WildChangesLogged)
JSON: $($result.JsonReportPath)
Trainer changes JSON: $($result.TrainerChangesReportPath)
Wild changes JSON: $($result.WildChangesReportPath)
Item changes JSON: $($result.ItemChangesReportPath)
Encounter zones JSON: $($result.EncounterZoneReportPath)
Seed summary JSON: $($result.SeedSummaryReportPath)
Spoiler log JSON: $($result.SpoilerLogReportPath)
Level caps JSON: $($result.BossLevelCapsReportPath)
Story gym/champion caps JSON: $($result.StoryGymLeagueCapsReportPath)
Ordered main-story battles JSON: $($result.StoryMajorBattleCapsReportPath)
Disable EXP Share via ExLaunch: $($result.DisableExpSharePatchEnabled)
Dynamic EXP cap IPS files: $($result.DynamicExpLevelCapPatchFilesWritten)
Story gym/champion EXP cap IPS files: $($result.StoryGymLeagueExpCapPatchFilesWritten)
EXP cap requires ExLaunch: $($result.ExpLevelCapRequiresExLaunch)
EXP cap ExLaunch config: $($result.ExpLevelCapExLaunchConfigPath)
ExLaunch module available: $($result.ExLaunchModuleAvailable)
ExLaunch module auto-deployed: $($result.ExLaunchModuleDeployed)
PC runtime controls: $($result.RuntimePcScriptApplied)
ExLaunch module target: $($result.ExLaunchModuleTargetRoot)
Installation folder: $($result.InstallationPackageRoot)
Installation guide: $($result.InstallationPackageReadmePath)
Auto-install requested: $($result.AutoInstallRequested)
Auto-install success count: $($result.AutoInstallSuccessCount)
Auto-install failure count: $($result.AutoInstallFailureCount)
ExeFS IPS files total: $($result.ExeFsPatchFilesWritten)
ExeFS patch root: $($result.ExeFsPatchRoot)
"@
            } else {
                $statusBox.Text = @"
Termine.
Sortie: $($result.Output)
Seed: $($result.Seed)
Personal modifies: $($result.PersonalEntriesEdited)
EXP donnees modifiees: $($result.ExpYieldsEdited)
Attaques modifiees: $($result.MovesEdited)
Types d'attaques modifies: $($result.MoveTypesEdited)
Puissances d'attaques modifiees: $($result.MovePowersEdited)
PP d'attaques modifies: $($result.MovePPEdited)
Precisions d'attaques modifiees: $($result.MoveAccuracyEdited)
Categories d'attaques modifiees: $($result.MoveCategoriesEdited)
Objets ramassables modifies: $($result.PickupItemsEdited)
Objets boutiques modifies: $($result.ShopItemsEdited)
Objets CT/TR modifies: $($result.TechnicalRecordsEdited)
Trainers modifies: $($result.TrainersEdited)
Pokemon de dresseurs traites: $($result.TrainerPokemonProcessed)
Boss etendus a 6: $($result.BossTeamsExpanded)
Equipes boss normalisees au cap strict: $($result.BossTeamsLevelNormalized)
Shinies dresseurs forces: $($result.TrainerShiniesForced)
Pokemon de dresseurs forces au stade final: $($result.TrainerSpeciesForceEvolved)
Equipes dresseurs themees par type: $($result.TrainerTypeThemedTrainers)
IA dresseurs maxees: $($result.TrainerAIMaxed)
Niveaux Dynamax dresseurs modifies: $($result.TrainerDynamaxLevelsEdited)
Flags CanDynamax dresseurs forces: $($result.TrainerDynamaxFlagsForced)
Changements detailles dresseurs journalises: $($result.TrainerChangesLogged)
Evolutions modifiees: $($result.EvolutionsEdited)
Evolutions amitie normalisees: $($result.FriendshipEvolutionsNormalized)
Evolutions echange normalisees: $($result.TradeEvolutionsNormalized)
Evolutions speciales normalisees: $($result.SpecialEvolutionsNormalized)
Gifts modifies: $($result.GiftsEdited)
Starters modifies: $($result.StartersEdited)
Fichiers dresseurs lies aux starters patches: $($result.StarterRelatedTrainerFilesEdited)
Slots dresseurs lies aux starters patches: $($result.StarterRelatedTrainerSlotsEdited)
Slots trades PNJ modifies: $($result.TradeSpeciesSlotsEdited)
Rencontres fixes modifiees: $($result.StaticEncountersEdited)
Slots hautes herbes modifies: $($result.GrassEncounterSlotsEdited)
Slots underground modifies: $($result.UndergroundSpeciesSlotsEdited)
Changements detailles nature journalises: $($result.WildChangesLogged)
JSON: $($result.JsonReportPath)
JSON changements dresseurs: $($result.TrainerChangesReportPath)
JSON changements nature: $($result.WildChangesReportPath)
JSON changements objets: $($result.ItemChangesReportPath)
JSON zones rencontres: $($result.EncounterZoneReportPath)
JSON resume seed: $($result.SeedSummaryReportPath)
JSON spoiler log: $($result.SpoilerLogReportPath)
JSON caps boss: $($result.BossLevelCapsReportPath)
JSON caps histoire arenes/Tarak: $($result.StoryGymLeagueCapsReportPath)
JSON combats majeurs ordre histoire: $($result.StoryMajorBattleCapsReportPath)
EXP Share via ExLaunch: $($result.DisableExpSharePatchEnabled)
Fichiers IPS levelcap EXP dynamique: $($result.DynamicExpLevelCapPatchFilesWritten)
Fichiers IPS cap EXP histoire arenes/Tarak: $($result.StoryGymLeagueExpCapPatchFilesWritten)
Cap EXP requiert ExLaunch: $($result.ExpLevelCapRequiresExLaunch)
Config ExLaunch cap EXP: $($result.ExpLevelCapExLaunchConfigPath)
Module ExLaunch disponible: $($result.ExLaunchModuleAvailable)
Module ExLaunch auto-deploye: $($result.ExLaunchModuleDeployed)
Controle runtime via PC: $($result.RuntimePcScriptApplied)
Destination module ExLaunch: $($result.ExLaunchModuleTargetRoot)
Dossier Installation: $($result.InstallationPackageRoot)
Guide Installation: $($result.InstallationPackageReadmePath)
Installation auto demandee: $($result.AutoInstallRequested)
Installations auto reussies: $($result.AutoInstallSuccessCount)
Installations auto en echec: $($result.AutoInstallFailureCount)
Fichiers IPS ExeFS total: $($result.ExeFsPatchFilesWritten)
Dossier patchs ExeFS: $($result.ExeFsPatchRoot)
"@
            }
            $message = if ($script:UiLanguage -eq "en") { "Generation complete." } else { "Génération terminée." }
            [void][System.Windows.Forms.MessageBox]::Show($form, $message, $form.Text, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch [System.Management.Automation.PipelineStoppedException] {
            $statusBox.Text = if ($script:UiLanguage -eq "en") { "Generation cancelled." } else { "Génération annulee." }
        } catch {
            $statusBox.Text = "Erreur: $($_.Exception.Message)"
        } finally {
            $runButton.Enabled = $true
        }
    })

    # --- Mise en cartes des onglets ------------------------------------
    # Posee ici, quand chaque onglet est entierement construit et traduit. Le
    # helper translate un groupe de controles dans une carte sans toucher a
    # leurs positions relatives : c'est la transformation la moins risquee sur
    # une disposition ecrite en coordonnees absolues.

    # Evolutions : trois idees distinctes que la liste unique melangeait.
    [void](Add-PfCardAround -Parent $evoTab -FromY 40 -ToY 50 -TitleSource $evoModeLabel -CardY 8)
    [void](Add-PfCardAround -Parent $evoTab -FromY 90 -ToY 245 `
        -TitleFr "Conditions d'évolution normalisées" -TitleEn "Normalised evolution conditions" -CardY 96)
    [void](Add-PfCardAround -Parent $evoTab -FromY 260 -ToY 340 `
        -TitleFr "Contraintes sur les chaînes" -TitleEn "Chain constraints" -CardY 340)

    # Nettoyage : les emulateurs vises, puis le compte rendu.
    [void](Add-PfCardAround -Parent $resetTab -FromY 50 -ToY 160 `
        -TitleFr "Émulateurs à nettoyer" -TitleEn "Emulators to clean" `
        -SubtitleSource $resetInfoLabel -CardY 8)

    # Starters et cadeaux : quatre idees, dont les starters manuels qui
    # meritent leur explication en sous-titre.
    # FromY 14 et non 40 : les libelles de colonne « Pokémon cadeaux » et
    # « Starters » sont a y=18. Les laisser dehors les faisait passer par-dessus
    # le titre de la carte.
    [void](Add-PfCardAround -Parent $giftTab -FromY 14 -ToY 50 `
        -TitleFr "Cadeaux et starters" -TitleEn "Gifts and starters" -CardY 8)
    [void](Add-PfCardAround -Parent $giftTab -FromY 120 -ToY 160 `
        -TitleFr "Starters manuels" -TitleEn "Manual starters" `
        -SubtitleSource $manualStarterGroupLabel -CardY 130)
    [void](Add-PfCardAround -Parent $giftTab -FromY 215 -ToY 230 `
        -TitleSource $tradeModeLabel -CardY 278)
    [void](Add-PfCardAround -Parent $giftTab -FromY 265 -ToY 280 `
        -TitleFr "Bornes de statistiques" -TitleEn "Stat bounds" -CardY 356)

    # Rencontres : deux cartes seulement. L'onglet est trop dense pour cinq,
    # et une carte coute une cinquantaine de pixels de chrome.
    [void](Add-PfCardAround -Parent $encounterTab -FromY 40 -ToY 190 `
        -TitleSource $staticModeLabel -CardY 8)
    [void](Add-PfCardAround -Parent $encounterTab -FromY 215 -ToY 400 -ToX 1100 `
        -TitleFr "Ce que tu vois et ce que tu affrontes" -TitleEn "What you see and what you fight" -CardY 242)

    # Pokemon : trois cartes, rendues possibles par la compaction de la
    # disposition. Un premier essai avait echoue faute de place - le contenu
    # allait jusqu'a y=500 sur 516, et une carte coute 46 px de bandeau plus 12
    # de marge. Le pas vertical etait de 74 px entre deux rangees de listes pour
    # des controles de 24 : c'est la que la place a ete prise, pas dans le
    # chrome. Le contenu descend maintenant a 494 en trois blocs au lieu d'un
    # seul de 482.
    #
    # A et B sont cote a cote (6..570 et 588..1098), C prend toute la largeur.
    # Les bornes FromX separent les deux colonnes du haut : sans elles le helper
    # prendrait tout ce qui tombe dans la plage verticale.
    [void](Add-PfCardAround -Parent $pokemonTab -FromY 8 -ToY 260 -FromX 0 -ToX 570 `
        -TitleFr "Types, talents et statistiques" -TitleEn "Types, abilities and stats" -CardY 8)
    [void](Add-PfCardAround -Parent $pokemonTab -FromY 8 -ToY 260 -FromX 580 -ToX 1120 `
        -TitleFr "Données des attaques" -TitleEn "Move data" -CardY 8)
    [void](Add-PfCardAround -Parent $pokemonTab -FromY 370 -ToY 500 `
        -TitleFr "Objets et expérience" -TitleEn "Items and experience" `
        -CardX 6 -CardWidth 1092 -CardY 334)

    # Dresseurs n'a PAS de carte, et c'est une decision mesuree, pas un reste.
    #
    # Ses 58 controles occupent 18..478, soit 460 px sur les 516 disponibles.
    # J'ai releve la hauteur de chacune de ses dix bandes de contenu : leur
    # somme fait 400 px. Il ne reste donc que 60 px de jeu pour neuf intervalles
    # - moins que les 72 px qu'il faudrait pour seulement 8 px entre chaque.
    # Deux bandes se touchent deja. L'onglet n'est pas aere : il est SATURE, et
    # aucune compaction n'y liberera les 58 px de chrome qu'une deuxieme carte
    # coute. Une carte unique tiendrait (46 + 460 + 12 = 518, contre 516 : deux
    # pixels de trop, recuperables), mais elle ne ferait que dessiner un cadre
    # autour de l'onglet entier et repeter le titre de page deja affiche en
    # haut. Un cadre qui n'apprend rien ne vaut pas son encombrement.
    #
    # Ce qui a ete fait a la place, parce que la capture le montrait : le
    # libelle « Attaques de secours Smogon » effacait la premiere lettre de sa
    # liste, et une douzaine de textes de l'onglet etaient sans accents.

    # Generation : les lignes d'accueil restent au-dessus, les options entrent
    # dans une carte.
    [void](Add-PfCardAround -Parent $generalTab -FromY 200 -ToY 425 `
        -TitleFr "Options de build" -TitleEn "Build options" -CardY 198)

    Update-PfCards

    # La coque est posee en dernier : elle reparente en bloc ce que tout le
    # reste de Show-Gui a construit, sans toucher a une seule coordonnee.
    Add-PfShell -Form $form -Tabs $tabs

    [void]$form.ShowDialog()
}
