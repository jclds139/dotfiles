## LOCAL BUILD ONLY SETTINGS ##

$out_dir = "./build";
$pdf_mode = 4;


## OVERLEAF SETTINGS ##

# Settings
$xdvipdfmx = "xdvipdfmx -z 6 -i dvipdfmx-unsafe.cfg -o %D %O %S";

# Workaround to allow pstricks transparency (https://github.com/overleaf/issues/issues/3449)
$dvipdf = "dvipdf -dNOSAFER -dALLOWPSTRANSPARENCY %O %S %D";


###############################
# Post processing of pdf file #
###############################

$compiling_cmd = "internal check_output_age %T %D";
$success_cmd = "internal gs_optimize %T %D";
$failure_cmd = $success_cmd;

# equivalent to -gt option. Used to prevent latexmk from skipping recompilation
# of output.log and output.pdf
$go_mode = 3;

# equivalent to -bibtex option. Run bibtex unconditionally when bbl files are
# out of date.
$bibtex_use = 2;

my $ORIG_PDF_AGE;

sub check_output_age {
    my $source_file = $_[0];
    my $output_file = $_[1];

    # get age of existing pdf if present
    $ORIG_PDF_AGE = -M $output_file
}

sub overleaf_post_process {
    my $source_file = $_[0];
    my $output_file = $_[1];
    my $source_without_ext = $source_file =~ s/\.tex$//r;
    my $output_without_ext = $output_file =~ s/\.pdf$//r;

    # Look for a knitr concordance file
    my $concordance_file = "${source_without_ext}-concordance.tex";
    if (-e $concordance_file) {
        print "Patching synctex file for knitr...\n";
        system("patchSynctex.R", $source_without_ext, $output_without_ext);
    }

    # Return early if pdf file doesn't exist or wasn't updated
    my $NEW_PDF_AGE = -M $output_file;
    return if !defined($NEW_PDF_AGE);
    return if defined($ORIG_PDF_AGE) && $NEW_PDF_AGE == $ORIG_PDF_AGE;

    # Figure out where qpdf is
    $qpdf //= "/usr/bin/qpdf";
    $qpdf = $ENV{QPDF} if defined($ENV{QPDF}) && -x $ENV{QPDF};
    return if ! -x $qpdf;
    $qpdf_opts //= "--linearize --newline-before-endstream";
    $qpdf_opts = $ENV{QPDF_OPTS} if defined($ENV{QPDF_OPTS});

    # Run qpdf
    my $optimised_file = "${output_file}.opt";
    system($qpdf, split(' ', $qpdf_opts), $output_file, $optimised_file);
    $qpdf_exit_code = ($? >> 8);
    print "qpdf exit code=$qpdf_exit_code\n";

    # Replace the output file if qpdf was successful
    # qpdf returns 0 for success, 3 for warnings (output pdf still created)
    return if !($qpdf_exit_code == 0 || $qpdf_exit_code == 3);
    print "Renaming optimised file to $output_file\n";
    rename($optimised_file, $output_file);

    print "Extracting xref table for $output_file\n";
    my $xref_file = "${output_file}xref";
    system("$qpdf --show-xref ${output_file} > ${xref_file}");
    $qpdf_xref_exit_code = ($? >> 8);
    print "qpdf --show-xref exit code=$qpdf_xref_exit_code\n";
}

sub gs_optimize {
    my $source_file = $_[0];
    my $output_file = $_[1];

    # overleaf_post_process($source_file, $output_file);

    my $source_without_ext = $source_file =~ s/\.tex$//r;
    my $output_without_ext = $output_file =~ s/\.pdf$//r;

    # Return early if pdf file doesn't exist or wasn't updated
    my $NEW_PDF_AGE = -M $output_file;
    return if !defined($NEW_PDF_AGE);
    return if defined($ORIG_PDF_AGE) && $NEW_PDF_AGE == $ORIG_PDF_AGE;

    # Figure out where gs is
    $gs //= "/usr/bin/gs";
    $gs = $ENV{GS} if defined($ENV{GS}) && -x $ENV{GS};
    return if ! -x $gs;
    $gs_opts //= "-dDOPS -dALLOWPSTRANSPARENCY -dOptimize=true -dCompatibilityLevel=1.7 -dSubsetFonts=true -dCompressFonts=true -dDetectDuplicateImages=true -dFastWebView=true";
    $gs_opts = $ENV{GS_OPTS} if defined($ENV{GS_OPTS});

    # Run gs
    my $optimised_file = "${output_file}.opt";
    system($gs, "-P-", "-dNOPAUSE", "-dBATCH", "-sDEVICE=pdfwrite", "-sOutputFile=${optimised_file}", split(' ', $gs_opts), "${output_file}");
    $gs_exit_code = ($? >> 8);
    print "gs exit code=$gs_exit_code\n";

    # Replace the output file if gs was successful
    # gs returns 0 for success
    return if !($gs_exit_code == 0);
    print "Renaming gs-optimised file to $output_file\n";
    rename($optimised_file, $output_file);

}
