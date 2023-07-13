{
  permittedInsecurePackages = [
    # Because it is the only choice in the GitHub Actions engine.
    # https://github.com/kachick/wait-other-jobs/blob/6a50464dd0f6a3cbde8ac50687ee246830f99075/CONTRIBUTING.md#why-using-nodejs16-instead-of-denobunnodejs18
    # NOTE: Cant't specify as `nodejs-16_x`
    "nodejs-16.20.0"
    "nodejs-16.20.1"
  ];
}
