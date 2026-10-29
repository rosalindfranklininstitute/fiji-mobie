# fiji-mobie

Container image for [Fiji](https://imagej.net/software/fiji/), an image processing distribution based on ImageJ, with the [MoBIE](https://mobie.github.io/) plugin installed for viewing and sharing multi-modal volume imaging data.

- User documentation for container: [rosalindfranklininstitute.github.io/volume-em-container-documentation](https://rosalindfranklininstitute.github.io/volume-em-container-documentation/software/fiji/)
- MoBIE documentation: [mobie.github.io](https://mobie.github.io/)

Images are published at [quay.io/rosalindfranklininstitute/fiji-mobie](https://quay.io/repository/rosalindfranklininstitute/fiji-mobie).

If you notice a problem or have a suggestion for the container builds, please [open an issue](https://github.com/rosalindfranklininstitute/fiji-mobie/issues).

## Tags
Images are tagged with the UTC build date, e.g., `fiji-mobie:20261029`. As the build install MoBIE from its update site and runs the Fiji updater, the image containers Fiji and MoBIE as they were on the build date (the MoBIE site is rolling, and its jars assume the library versions in the current Fiji site).

## Building a new image

In **Actions** run the **Build Fiji-MoBIE container image and publish to Quay.io** flow, checking **latest** if you want the image to be tagged with `latest`.

To build locally, use `docker build --no-cache .`, otherwise cached layers may contain an older Fiji.

### Other maintenance
Occasionally, action versions in the GitHub workflow may need updating.

2026-10-29: The Dockerfile contains a workaround for MoBIE, which should be removed once fixed upstream, that adds the AWS SDK v1 jars to Fiji. See the [Known issues](#known-issues).

## Known issues

- **AWS SDK v1.** Current Fiji no longer ships the AWS SDK v1 libraries that MoBIE still uses, which makes MoBIE fail with `NoClassDefFoundError: com/amazonaws/services/s3/model/S3ObjectInputStream`. See [mobie-viewer-fiji#1336](https://github.com/mobie/mobie-viewer-fiji/issues/1336). The Dockerfile adds the required jars from Maven Central.
- **BigVolumeViewer.** Some commands (e.g. **Plugins > Debug > Dump Stack**) report `NoClassDefFoundError: bvv/vistools/BvvHandle`, as the BigVolumeViewer library is not included. This does not affect opening MoBIE projects.

## Image verification and metadata

Images are signed in the build workflow using [cosign](https://docs.sigstore.dev/cosign/) keyless signing. To verify the `20261029` tag, for example:
```bash
cosign verify quay.io/rosalindfranklininstitute/fiji-mobie:20261029 \
  --certificate-identity https://github.com/rosalindfranklininstitute/fiji-mobie/.github/workflows/build-publish.yml@refs/heads/main \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```
Note a signature shows who built the image, not that Fiji, MoBIE or the Ubuntu packages are trustworthy.

Each image also carries build provenance and a software bill of materials (SBOM), which can be read with:
```bash
docker buildx imagetools inspect quay.io/rosalindfranklininstitute/fiji-mobie:20261029 --format '{{ json .Provenance }}'
docker buildx imagetools inspect quay.io/rosalindfranklininstitute/fiji-mobie:20261029 --format '{{ json .SBOM }}'
```

The SBOM lists the Java libraries in Fiji as well as the Ubuntu packages, so it can be used to find the versions in an image, e.g. for MoBIE and ImageJ:

```bash
docker buildx imagetools inspect quay.io/rosalindfranklininstitute/fiji-mobie:20261029 --format '{{ json .SBOM }}' \
  | jq -r '.SPDX.packages[] | select(.name | test("^(mobie-viewer-fiji|
```

## Licence

The container image and Fiji are licensed under GNU General Public License v3. ImageJ2 core and MoBIE are licensed under BSD-2-Clause license. Other bundled components may have different licenses; see `/opt/Fiji/licenses`.
