"""Heuristic file for heudiconv."""

def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    """Key template."""
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes


def infotodict(seqinfo):
    """Create information dict for each image.

    Heuristic evaluator for determining which runs belong where allowed template fields
    follow python string module:
    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """
    t1w = create_key('sub-{subject}/anat/sub-{subject}_T1w')
    t2 = create_key('sub-{subject}/anat/sub-{subject}_inplaneT2')
    mtlc = create_key('sub-{subject}/anat/sub-{subject}_mt-lc')
    func_test = create_key('sub-{subject}/func/sub-{subject}_task-amass_run-{item:02d}_dir-PA_bold')
    fmap = create_key('sub-{subject}/fmap/sub-{subject}_run-{item:02d}_dir-AP_epi')

    info = {
        t1w: [],
        t2: [],
        mtlc: [],
        func_test: [],
        fmap: []
    }

    # Debug: print all seqinfo to understand what we're getting
    # This will help identify why some series are being skipped
    print(f"\n[HEURISTIC DEBUG] Processing {len(seqinfo)} sequences:")
    for idx, s in enumerate(seqinfo):
        print(f"  [{idx}] series_id={s.series_id}, dcm_dir={s.dcm_dir_name}, desc={s.series_description}, dim4={s.dim4}")

    for s in seqinfo:
        """
        The namedtuple `s` contains the following fields:

        * total_files_till_now
        * example_dcm_file
        * series_id
        * dcm_dir_name
        * unspecified2
        * unspecified3
        * dim1
        * dim2
        * dim3
        * dim4
        * TR
        * TE
        * protocol_name
        * is_motion_corrected
        * is_derived
        * patient_id
        * study_description
        * referring_physician_name
        * series_description
        * image_type
        """

        if ('T1' in s.series_description):
            info[t1w].append(s.series_id)
        if ('T2' in s.series_description):
            info[t2].append(s.series_id)
        if ('Xing2018' in s.series_description):
            info[mtlc].append(s.series_id)
        if ('test' in s.series_description):
            info[func_test].append(s.series_id)
        if ('CAL' in s.series_description):
            info[fmap].append(s.series_id)

    # Debug: print what we collected
    print(f"\n[HEURISTIC DEBUG] Collected sequences:")
    print(f"  T1w: {info[t1w]}")
    print(f"  inplaneT2: {info[t2]}")
    print(f"  mt-lc: {info[mtlc]}")
    print(f"  func_test: {info[func_test]}")
    print(f"  fmap: {info[fmap]}")
    print()

    return info
