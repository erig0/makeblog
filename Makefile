# vim: foldmethod=marker fml=1
#
# Copyright (c) 2014, Eric Garver {{{1
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# {{{1
MAKEFILE_LIST := ${.MAKE.MAKEFILES}

# External tools {{{1
#
MARKDOWN?=Markdown

# Defaults for site. {{{1
# Any of these can be changed to ones liking.  Best method is to set them in a
# new makefile and include this makefile.
#
DESTDIR?=www
DEPFILE?=.depend
BLOG_DIR?=blog
BLOG_IMAGES_DIR?=images
BLOG_VIDEOS_DIR?=videos
BLOG_HISTORY?=${BLOG_DIR}/history.html
BLOG_RSS?=${BLOG_DIR}/rss.xml
TEMPLATE_FILES?=
TEMPLATE_FILES_LATE?=
HTML_FILES?=
HTML_HEAD_FILE?=
HAVE_NANO_LIGHTBOX?=

#
# BLOG is optional {{{1
#
.if !empty(BLOG_DIR)
all: blog_posts
.PHONY: blog_posts

# Find all the blog posts, {{{2
# Means directory names determine chronological order of blog posts.
#
BLOG_POSTS !=find ${BLOG_DIR} -type f -mindepth 2 -maxdepth 2 \! -name '*.draft' |sort; echo ""
BLOG_DRAFTS!=find ${BLOG_DIR} -type f -mindepth 2 -maxdepth 2    -name '*.draft' |sort; echo ""

# Find all the blog media {{{2
# 
BLOG_POSTS_IMAGES!=find ${BLOG_DIR}/*/${BLOG_IMAGES_DIR} -type f 2>/dev/null; echo ""
BLOG_POSTS_VIDEOS!=find ${BLOG_DIR}/*/${BLOG_VIDEOS_DIR} -type f 2>/dev/null; echo ""

# HACK to get around parser bug
#
HASH :=\#

# Build some variables for relationships {{{2
#
PREV :=
NEXT_INDEX := DUMMY OFFSET_SEED
.for post in ${BLOG_POSTS}
${post}_prevPost := ${PREV}
${post}_nextPost := ${BLOG_POSTS:[${NEXT_INDEX:[${HASH}]}]}

PREV := ${post}
NEXT_INDEX := ${NEXT_INDEX} ${post}
.endfor

.for post in ${BLOG_POSTS} ${BLOG_DRAFTS}
${post}_fileToTitle = ${post:R:C/${BLOG_DIR}[\/][^\/]*[\/](.*)/\1/g:C/-([smtd]|ve|ll|re)(-|\$)/'\1 /g:C/[-_]([^-_])/ \1/g:C/[-_]([-_])/ \1/g}
.endfor

BLOG_POSTS_REV := ${BLOG_POSTS:[-1..1]}
BLOG_POSTS_MONTHS := ${BLOG_POSTS_REV:C/${BLOG_DIR}.(......).*/\1/g}
BLOG_POSTS_MONTHS := ${BLOG_POSTS_MONTHS:u}
.for month in ${BLOG_POSTS_MONTHS}
BLOG_POSTS_MONTHS_${month} !=date -j +'%B %Y' ${month}010000
.endfor

# Dependency file for post prev/next updating. (delete case) {{{2
#
.sinclude "${DEPFILE}"
blog_posts: ${DEPFILE}
${DEPFILE}: ${BLOG_POSTS} ${MAKEFILE_LIST}
	@echo -e "DEP\tblog_posts"
	@mkdir -p ${.TARGET:H}
	@echo "" > ${.TARGET}
.for post in ${BLOG_POSTS}
	@echo "${DESTDIR}/${post:R}.html ${.TARGET} ${BLOG_HISTORY}: ${${post}_prevPost}" >> ${.TARGET}
	@echo "${DESTDIR}/${post:R}.html ${.TARGET} ${BLOG_HISTORY}: ${${post}_nextPost}" >> ${.TARGET}
	@echo "${post}:" >> ${.TARGET}
.endfor

# Dependencies for post prev/next updating. (new case) {{{2
#
.for post in ${BLOG_POSTS}
${DESTDIR}/${post:R}.html: ${${post}_prevPost}
${DESTDIR}/${post:R}.html: ${${post}_nextPost}
.endfor

# Generate rules to build posts {{{2
#
.for post in ${BLOG_POSTS} ${BLOG_DRAFTS}
blog_posts: ${DESTDIR}/${post:R}.html
${DESTDIR}/${post:R}.html: ${post} ${HTML_HEAD_FILE} ${TEMPLATE_FILES} ${TEMPLATE_FILES_LATE} ${MAKEFILE_LIST}
	@echo -e "HTML\t${post}"
	@mkdir -p ${.TARGET:H}
	@echo "<!DOCTYPE html>" > ${.TARGET}
	@echo "<head>"  >> ${.TARGET}
	@cat ${HTML_HEAD_FILE} >> ${.TARGET}
.if empty(HAVE_NANO_LIGHTBOX)
	@echo "<script language=\"javascript\" type=\"text/javascript\">"  >> ${.TARGET}
	@echo "/* dummy */ function nanolightbox (node) { return true; }"  >> ${.TARGET}
	@echo "</script>"  >> ${.TARGET}
.endif
	@echo "</head>" >> ${.TARGET}
	@echo "<body>"  >> ${.TARGET}
.for template in ${TEMPLATE_FILES}
	@cat ${template} >> ${.TARGET}
.endfor
#
# cat post content
# replace custom tags/markdown
# add title and date
#
	@echo "<div class=\"blog_post scale\">"  >> ${.TARGET}
	@echo "<h2>${${post}_fileToTitle}</h2>"  >> ${.TARGET}
	@echo "<p class=\"blog_post_date\">$$(date -j +'%B %e, %Y' ${post:C/${BLOG_DIR}.(............).*/\1/g})</p>" >> ${.TARGET}
	@cat ${post} \
	 | sed -e 's/[[]img[]][(]\([^).]*\)[.]\([^)]*\)[)]/<a href="\/${post:H:S/\//\\\//g}\/\1.\2" onclick="return nanolightbox(this);"><img src="\/${post:H:S/\//\\\//g}\/\1_thumb.\2" \/><\/a>/g' \
	       -e 's/[[]video[]][(]\([^).]*\)[.]\([^)]*\)[)]/<video controls="true" preload="auto"><source src="\/${post:H:S/\//\\\//g}\/\1.ogv" type="video\/ogg;codecs=theora,vorbis" \/><source src="\/${post:H:S/\//\\\//g}\/\1.mp4" type="video\/mp4;codecs=h264,aac" \/><source src="\/${post:H:S/\//\\\//g}\/\1.mp4" \/>Your web browser cannot play this video.<\/video>/g' \
	 | $(MARKDOWN) \
	 >> ${.TARGET}
	@echo "</div>" >> ${.TARGET}
#
# Prev/Next links
#
	@echo "<div class=\"blog_post_footer scale\">"  >> ${.TARGET}
.if !empty(${post}_prevPost)
	@echo "<p class=\"blog_post_prev\">" >> ${.TARGET}
	@echo "<a href=\"/${${post}_prevPost:R}.html\">Previous Post</a>" >> ${.TARGET}
	@echo "</p>" >> ${.TARGET}
.endif
.if !empty(${post}_nextPost)
	@echo "<p class=\"blog_post_next\">" >> ${.TARGET}
	@echo "<a href=\"/${${post}_nextPost:R}.html\">Next Post</a>" >> ${.TARGET}
	@echo "</p>" >> ${.TARGET}
.endif
	@echo "</div>" >> ${.TARGET}
.for template in ${TEMPLATE_FILES_LATE}
	@cat ${template} >> ${.TARGET}
.endfor
	@echo "</body>" >> ${.TARGET}
	@echo "</html>" >> ${.TARGET}

.endfor # for each ${BLOG_POSTS}

# Create blog index.html as most recent post {{{2
#
.if !empty(BLOG_POSTS)
blog_posts: ${DESTDIR}/${BLOG_DIR}/index.html
${DESTDIR}/${BLOG_DIR}/index.html: ${DESTDIR}/${BLOG_POSTS:[-1]:R}.html
	@cp ${.ALLSRC} ${.TARGET}
.endif

# blog history index {{{2
#
HTML_FILES+=${BLOG_HISTORY}

${BLOG_HISTORY}: ${BLOG_POSTS} ${MAKEFILE_LIST}
	@echo -e "HTML\t${.TARGET}"
	@mkdir -p ${.TARGET:H}
#
# First build the table of contents
#
	@echo "<div id=\"blog_history_toc\" class=\"scale\">" > ${.TARGET}
	@echo "<ul>" >> ${.TARGET}
.for month in ${BLOG_POSTS_MONTHS}
	@echo -n "<li><a href=\"#${month}\">" >> ${.TARGET}
	@echo -n "${BLOG_POSTS_MONTHS_${month}}" >> ${.TARGET}
	@echo "</a></li>" >> ${.TARGET}
.endfor
	@echo "</ul>" >> ${.TARGET}
	@echo "</div>" >> ${.TARGET}
#
# Add each post, group by months
#
	@echo "<div id=\"blog_history\" class=\"scale\">" >> ${.TARGET}
.for month in ${BLOG_POSTS_MONTHS}
	@echo -n "<a name=\"${month}\">" >> ${.TARGET}
	@echo -n "<h4>${BLOG_POSTS_MONTHS_${month}}</h4>" >> ${.TARGET}
	@echo "</a>" >> ${.TARGET}
.for post in ${BLOG_POSTS_REV:M*${month}*}
	@echo "<ul>" >> ${.TARGET}
	@echo -n "<li><a href=\"/${post:R}.html\">" >> ${.TARGET}
	@echo -n "${${post}_fileToTitle}" >> ${.TARGET}
	@echo "</a></li>" >> ${.TARGET}
	@echo "</ul>" >> ${.TARGET}
.endfor
.endfor
	@echo "</div>" >> ${.TARGET}

# Create RSS feed
#
.if !empty(BLOG_RSS_URL)
blog_posts: ${DESTDIR}/${BLOG_RSS}
${DESTDIR}/${BLOG_RSS}: ${BLOG_POSTS_REV:[1..10]} ${MAKEFILE_LIST}
	@echo -e "RSS\t${.TARGET}"
	@mkdir -p ${.TARGET:H}
	@echo -n "<?xml version=\"1.0\"?>" > ${.TARGET}
	@echo -n "<rss version=\"2.0\">" >> ${.TARGET}
	@echo -n "<channel>" >> ${.TARGET}
	@echo -n "<title>" >> ${.TARGET}
	@echo -n "${BLOG_RSS_TITLE}" >> ${.TARGET}
	@echo -n "</title>" >> ${.TARGET}
	@echo -n "<link>" >> ${.TARGET}
	@echo -n "${BLOG_RSS_URL}/${BLOG_DIR}" >> ${.TARGET}
	@echo -n "</link>" >> ${.TARGET}
	@echo -n "<description>" >> ${.TARGET}
	@echo -n "${BLOG_RSS_DESC}" >> ${.TARGET}
	@echo -n "</description>" >> ${.TARGET}
.for post in ${BLOG_POSTS_REV:[1..10]}
	@echo -n "<item>" >> ${.TARGET}
	@echo -n "<title>" >> ${.TARGET}
	@echo -n "${${post}_fileToTitle}" >> ${.TARGET}
	@echo -n "</title>" >> ${.TARGET}
	@echo -n "<link>" >> ${.TARGET}
	@echo -n "${BLOG_RSS_URL}/${post:R}.html" >> ${.TARGET}
	@echo -n "</link>" >> ${.TARGET}
	@echo -n "<pubDate>" >> ${.TARGET}
	@echo -n "$$(date -j +'%a, %d %b %Y %H:%M:%S %Z' ${post:C/${BLOG_DIR}.(............).*/\1/g})" >> ${.TARGET}
	@echo -n "</pubDate>" >> ${.TARGET}
	@echo -n "</item>" >> ${.TARGET}
.endfor
	@echo -n "</channel>" >> ${.TARGET}
	@echo -n "</rss>" >> ${.TARGET}
.endif

.for image in ${BLOG_POSTS_IMAGES}
blog_posts: ${DESTDIR}/${image} ${DESTDIR}/${image:R}_thumb.${image:E}
${DESTDIR}/${image}: ${image}
	@echo -e "SCALE\t${image}"
	@mkdir -p ${.TARGET:H}
	@convert ${image} -quality 85 -scale 1600x1600 ${.TARGET}

${DESTDIR}/${image:R}_thumb.${image:E}: ${image}
	@echo -e "THUMB\t${image}"
	@mkdir -p ${.TARGET:H}
	@convert ${image} -quality 65 -thumbnail 256x256 ${.TARGET}

.endfor # for each ${BLOG_POSTS_IMAGES}

.for video in ${BLOG_POSTS_VIDEOS}
blog_posts: ${DESTDIR}/${video:R}.ogv
${DESTDIR}/${video:R}.ogv: ${video}
	@echo -e "OGG\t${video}"
	@mkdir -p ${.TARGET:H}
	@make_ogv.sh ${video} ${.TARGET}

blog_posts: ${DESTDIR}/${video:R}.mp4
${DESTDIR}/${video:R}.mp4: ${video}
	@echo -e "MP4\t${video}"
	@mkdir -p ${.TARGET:H}
	@make_mp4.sh ${video} ${.TARGET}

.endfor # for each ${BLOG_POSTS_VIDEOS}

.endif # BLOG_DIR exists

# Static HTML files {{{1
#
all: html_files
.PHONY: html_files

# Generate rules for static HTML files {{{2
#
html_files:
.for html_file in ${HTML_FILES}
html_files: ${DESTDIR}/${html_file:R}.html
${DESTDIR}/${html_file:R}.html: ${html_file} ${HTML_HEAD_FILE} ${TEMPLATE_FILES} ${TEMPLATE_FILES_LATE} ${MAKEFILE_LIST}
	@echo -e "HTML\t${html_file}"
	@mkdir -p ${.TARGET:H}
	@echo "<!DOCTYPE html>" > ${.TARGET}
	@echo "<head>"  >> ${.TARGET}
	@cat ${HTML_HEAD_FILE} >> ${.TARGET}
.if empty(HAVE_NANO_LIGHTBOX)
	@echo "<script language=\"javascript\" type=\"text/javascript\">"  >> ${.TARGET}
	@echo "/* dummy */ function nanolightbox (node) { return true; }"  >> ${.TARGET}
	@echo "</script>"  >> ${.TARGET}
.endif
	@echo "</head>" >> ${.TARGET}
	@echo "<body>"  >> ${.TARGET}
.for template in ${TEMPLATE_FILES}
	@cat ${template} >> ${.TARGET}
.endfor
	@cat ${html_file} >> ${.TARGET}
.for template in ${TEMPLATE_FILES_LATE}
	@cat ${template} >> ${.TARGET}
.endfor
	@echo "</body>" >> ${.TARGET}
	@echo "</html>" >> ${.TARGET}

.endfor # for each ${HTML_FILES}

# Static files {{{1
#
all: static_files
.PHONY: static_files

# Generate rules for static files {{{2
#
.for static_file in ${STATIC_FILES}
static_files: ${DESTDIR}/${static_file}
${DESTDIR}/${static_file}: ${static_file} ${MAKEFILE_LIST}
	@echo -e "STATIC\t${static_file}"
	@mkdir -p ${.TARGET:H}
	@cp ${static_file} ${.TARGET} 
.endfor # for each ${STATIC_FILES}

# symlinks {{{1
#
all: symlinks
.PHONY: symlinks

# Generate rules for static files {{{2
#
symlinks:
.for symlink target in ${SYMLINKS}
symlinks: ${DESTDIR}/${symlink}
${DESTDIR}/${symlink}: ${MAKEFILE_LIST}
	@echo -e "LN\t${symlink}"
	@mkdir -p ${.TARGET:H}
	@ln -sf ${target} ${.TARGET} 
.endfor # for each ${SYMLINKS}

# Global/Main targets {{{1
#
.MAIN: all
.PHONY: all clean 

clean:
	-rm -rf ${DEPFILE}

# Don't print the --- target --- with -j
#
.MAKE.JOB.PREFIX=
