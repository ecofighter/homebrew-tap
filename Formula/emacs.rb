class Emacs < Formula
  desc "GNU Emacs text editor"
  homepage "https://www.gnu.org/software/emacs/"
  url "https://ftp.gnu.org/gnu/emacs/emacs-29.4.tar.xz"
  mirror "https://ftpmirror.gnu.org/emacs/emacs-29.4.tar.xz"
  sha256 "ba897946f94c36600a7e7bb3501d27aa4112d791bfe1445c61ed28550daca235"
  license "GPL-3.0-or-later"
  revision 1

  head do
    url "https://github.com/emacs-mirror/emacs.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "gnu-sed" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "texinfo" => :build
  depends_on "gmp"
  depends_on "gnutls"
  depends_on "gtk+3"
  depends_on "jansson"
  depends_on "libgccjit"
  depends_on "sqlite"
  depends_on "tree-sitter"

  uses_from_macos "libxml2"
  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  on_linux do
    depends_on "jpeg-turbo"
  end

  def install
    # Mojave uses the Catalina SDK which causes issues like
    # https://github.com/Homebrew/homebrew-core/issues/46393
    # https://github.com/Homebrew/homebrew-core/pull/70421
    ENV["ac_cv_func_aligned_alloc"] = "no" if OS.mac? && MacOS.version == :mojave

    args = %W[
      --disable-acl
      --disable-silent-rules
      --enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp
      --infodir=#{info}/emacs
      --prefix=#{prefix}
      --with-native-compilation=aot
      --with-gnutls
      --without-x
      --with-pgtk
      --with-xml2
      --without-dbus
      --with-modules
      --without-ns
      --without-imagemagick
      --without-selinux
      --with-tree-sitter
      --with-sqlite3
    ]

    if build.head?
      ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"
      system "./autogen.sh"
    end

    File.write "lisp/site-load.el", <<~EOS
      (setq exec-path (delete nil
        (mapcar
          (lambda (elt)
            (unless (string-match-p "Homebrew/shims" elt) elt))
          exec-path)))
    EOS

    system "./configure", *args
    system "make"
    system "make", "install"

    # Follow MacPorts and don't install ctags from Emacs. This allows Vim
    # and Emacs and ctags to play together without violence.
    (bin/"ctags").unlink
    (man1/"ctags.1.gz").unlink
  end

  service do
    run [opt_bin/"emacs", "--fg-daemon"]
    keep_alive true
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
